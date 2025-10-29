import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/service_call/service_call_submitted/service_call_submitted_event.dart';
import 'package:salsa/blocs/service_call/service_call_submitted/service_call_submitted_repository.dart';
import 'package:salsa/blocs/service_call/service_call_submitted/service_call_submitted_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/upload_s3_service.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model_ext.dart';

import '../../../components/services/hive_clear_service.dart';
import '../../../models/service_call/transaction_info_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';

class ServiceCallSubmittedBloc
    extends Bloc<ServiceCallSubmittedEvent, ServiceCallSubmittedState> {
  final ServiceCallSubmittedRepository repository;

  String _normalizeHiveKey(String key) =>
      key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  ServiceCallSubmittedBloc({required this.repository})
      : super(ValidationInitial()) {
    on<SubmitValidation>(_onSubmitValidation);
    on<RetryUpload>(_onRetryUpload);
    on<LoadValidationPartial>(_onLoadValidationPartial);
    on<ScFinalValidationRequested>(_onScFinalValidationRequested);
  }

  Future<void> _onScFinalValidationRequested(
    ScFinalValidationRequested event,
    Emitter<ServiceCallSubmittedState> emit,
  ) async {
    emit(ScProceedToOtpDialog(event.formState));
  }

  Future<void> _onSubmitValidation(
    SubmitValidation event,
    Emitter<ServiceCallSubmittedState> emit,
  ) async {
    emit(ValidationSubmitting());
    try {
      final box = await Hive.openBox<ServiceCallValidationEntryModel>(
          kServiceCallHiveBox);
      final entries =
          box.values.where((entry) => entry.transNo == event.transNo).toList();

      if (entries.isEmpty) {
        emit(ValidationFailure("Data validasi tidak ditemukan."));
        return;
      }

      final payload = entries.map((entry) => entry.toJson()).toList();

      final infoBox =
          await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
      final normalizedKey = _normalizeHiveKey(event.transNo);
      final transactionInfo = infoBox.get(normalizedKey);

      final result = await repository.submitValidation(
          event.transNo,
          event.createdBy,
          event.createdByName,
          event.createdByIP,
          event.pathAttachment,
          payload,
          transactionInfo);

      if (result['status'] == 'OK') {
        emit(ValidationUploadInProgress());
        final transNo = result['result']['trans_no'];
        final presignedDetail = result['result']['detail'];

        final uploadResult = await uploadAllImagesToS3(transNo, presignedDetail,
            progressCubit: event.progressCubit);

        if (uploadResult.allSuccess) {
          await clearTransactionData(event.transNo);
          final queueBox =
              await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
          final task = ConfirmationTaskModel(transNo: event.transNo);
          await queueBox.put(event.transNo, task);
          emit(ValidationSuccess(transNo: event.transNo, presignedDetail: []));
        } else {
          final cacheBox = Hive.box<Map<dynamic, dynamic>>(
              kServiceCallValidationPartialHiveBox);
          await cacheBox.put(event.transNo, {
            'transNo': event.transNo,
            'failedFiles': uploadResult.failedFiles,
            'presignedDetail': presignedDetail,
            'storeName': event.storeName,
            'module': 'SC',
          });
          emit(ValidationUploadPartial(
            successCount: uploadResult.successCount,
            failureCount: uploadResult.failureCount,
            failedFiles: uploadResult.failedFiles,
            transNo: event.transNo,
            presignedDetail: presignedDetail,
          ));
        }
      } else {
        emit(ValidationFailure(result['message'] ?? 'Gagal submit'));
      }
    } catch (e, stacktrace) {
      emit(ValidationFailure("Error: ${e.toString()}"));
    }
  }

  Future<void> _onRetryUpload(
    RetryUpload event,
    Emitter<ServiceCallSubmittedState> emit,
  ) async {
    emit(ValidationSubmitting());

    try {
      final result = await uploadAllImagesToS3(
        event.transNo,
        event.presignedDetail,
        filter: event.failedFiles,
        progressCubit: event.progressCubit,
      );

      if (result.allSuccess) {
        await clearTransactionData(event.transNo);
        final queueBox =
            await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
        final task = ConfirmationTaskModel(transNo: event.transNo);
        await queueBox.put(event.transNo, task);

        emit(ValidationSuccess(
          transNo: event.transNo,
          presignedDetail: event.presignedDetail,
        ));
      } else {
        final cacheBox = Hive.box<Map<dynamic, dynamic>>(
            kServiceCallValidationPartialHiveBox); // Use Hive.box
        // Ambil data lama untuk mempertahankan field lain jika ada
        final oldData =
            Map<String, dynamic>.from(cacheBox.get(event.transNo) ?? {});
        await cacheBox.put(event.transNo, {
          ...oldData,
          // Pertahankan data lama
          'transNo': event.transNo,
          'failedFiles': result.failedFiles,
          // Update file gagal
          'presignedDetail': event.presignedDetail,
          // Mungkin tidak perlu update presigned?
        });

        emit(ValidationUploadPartial(
          successCount: result.successCount,
          failureCount: result.failureCount,
          failedFiles: result.failedFiles,
          transNo: event.transNo,
          presignedDetail: event.presignedDetail,
        ));
      }
    } catch (e) {
      emit(ValidationFailure("Retry error: ${e.toString()}"));
    }
  }

  Future<void> _onLoadValidationPartial(
    LoadValidationPartial event,
    Emitter<ServiceCallSubmittedState> emit,
  ) async {
    try {
      final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(
          kServiceCallValidationPartialHiveBox); // Gunakan tipe yang benar
      final cached = cacheBox.get(event.transNo);

      if (cached != null) {
        final Map<String, dynamic> typedCached =
            Map<String, dynamic>.from(cached);
        emit(ValidationUploadPartial(
          successCount: 0,
          failureCount: (typedCached['failedFiles'] as List?)?.length ?? 0,
          failedFiles: List<String>.from(typedCached['failedFiles'] ?? []),
          transNo: event.transNo,
          presignedDetail:
              List<dynamic>.from(typedCached['presignedDetail'] ?? []),
        ));
      }
    } catch (e) {
      emit(ValidationFailure("Load cache error: ${e.toString()}"));
    }
  }
}

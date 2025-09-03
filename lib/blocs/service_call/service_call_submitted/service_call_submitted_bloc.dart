import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/service_call/service_call_submitted/service_call_submitted_event.dart';
import 'package:salsa/blocs/service_call/service_call_submitted/service_call_submitted_repository.dart';
import 'package:salsa/blocs/service_call/service_call_submitted/service_call_submitted_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/upload_s3_service.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model_ext.dart';

import '../../../models/service_call/transaction_info_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';

class ServiceCallSubmittedBloc
    extends Bloc<ServiceCallSubmittedEvent, ServiceCallSubmittedState> {
  final ServiceCallSubmittedRepository repository;
  String _normalizeHiveKey(String key) => key.replaceAll('/', '');

  ServiceCallSubmittedBloc({required this.repository})
      : super(ValidationInitial()) {
    on<SubmitValidation>(_onSubmitValidation);
    on<RetryUpload>(_onRetryUpload);
    on<LoadValidationPartial>(_onLoadValidationPartial);
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

      final infoBox = await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
      final normalizedKey = _normalizeHiveKey(event.transNo);
      final transactionInfo = infoBox.get(normalizedKey);


      // 1. Panggil API untuk mendapatkan URL Presigned
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

        // 3. EMIT STATE BERDASARKAN HASIL UPLOAD
        if (uploadResult.allSuccess) {
          final toDelete = box.keys
              .where((key) => box.get(key)?.transNo == transNo)
              .toList();
          await box.deleteAll(toDelete);

          final infoBox = await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
          final normalizedKey = _normalizeHiveKey(event.transNo);
          await infoBox.delete(normalizedKey);

          final queueBox = await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
          final task = ConfirmationTaskModel(transNo: transNo);
          // Kita gunakan transNo sebagai key agar tidak ada duplikasi
          await queueBox.put(transNo, task);

          // Pancarkan state sukses final
          emit(ValidationSuccess(
              transNo: transNo,
              presignedDetail: [])); // presignedDetail bisa dikosongkan
        } else {
          // Jika gagal sebagian, pancarkan state ValidationUploadPartial
          // Simpan juga info retry ke cache di sini
          final cacheBox =
              await Hive.openBox(kServiceCallValidationPartialHiveBox);
          await cacheBox.put(transNo, {
            'transNo': transNo,
            'failedFiles': uploadResult.failedFiles,
            'presignedDetail': presignedDetail,
          });

          emit(ValidationUploadPartial(
            successCount: uploadResult.successCount,
            failureCount: uploadResult.failureCount,
            failedFiles: uploadResult.failedFiles,
            transNo: transNo,
            presignedDetail: presignedDetail,
          ));
        }
      } else {
        emit(ValidationFailure(result['message'] ?? 'Gagal submit'));
      }
    } catch (e) {
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

      final cacheBox = await Hive.openBox(kServiceCallValidationPartialHiveBox);
      final box = await Hive.openBox<ServiceCallValidationEntryModel>(
          kServiceCallHiveBox);

      if (result.allSuccess) {
        // Cleanup Hive
        final toDelete = box.keys.where((key) {
          final item = box.get(key);
          return item?.transNo == event.transNo;
        }).toList();
        await box.deleteAll(toDelete);

        final infoBox = await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
        final normalizedKey = _normalizeHiveKey(event.transNo);
        await infoBox.delete(normalizedKey);

        await cacheBox.delete(event.transNo);
        await cacheBox.flush();

        emit(ValidationSuccess(
          transNo: event.transNo,
          presignedDetail: event.presignedDetail,
        ));

        // Reset state setelah success → agar tombol kembali normal
        // emit(ValidationInitial());
      } else {
        await cacheBox.put(event.transNo, {
          'transNo': event.transNo,
          'failedFiles': result.failedFiles,
          'presignedDetail': event.presignedDetail,
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
      final cacheBox = await Hive.openBox('validation_partial_cache');
      final cached = cacheBox.get(event.transNo);

      if (cached != null) {
        emit(ValidationUploadPartial(
          successCount: 0,
          failureCount: cached['failedFiles']?.length ?? 0,
          failedFiles: List<String>.from(cached['failedFiles'] ?? []),
          transNo: event.transNo,
          presignedDetail: List<dynamic>.from(cached['presignedDetail'] ?? []),
        ));
      }
    } catch (e) {
      emit(ValidationFailure("Load cache error: ${e.toString()}"));
    }
  }
}

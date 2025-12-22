import 'dart:developer';

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
import '../../../models/service_call/problem_source_model.dart';
import '../../../models/service_call/transaction_info_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';
import '../../../screens/common/services/confirmation_service.dart';
import '../../service/service_repository.dart';

class ServiceCallSubmittedBloc
    extends Bloc<ServiceCallSubmittedEvent, ServiceCallSubmittedState> {
  final ServiceCallSubmittedRepository repository;
  String _cachedAhoNumber = '';
  final serviceRepo = ServiceTaskRepository();

  String _normalizeHiveKey(String key) =>
      key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  ServiceCallSubmittedBloc({required this.repository})
      : super(ValidationInitial()) {
    on<SubmitValidation>(_onSubmitValidation);
    on<RetryUpload>(_onRetryUpload);
    on<LoadValidationPartial>(_onLoadValidationPartial);
    on<ScFinalValidationRequested>(_onScFinalValidationRequested);
    on<AhoInputCompleted>(_onAhoInputCompleted);
  }

  Future<bool> _checkIfAhoIsNeeded(
      String transNo, List<ProblemSourceModel> problemSources) async {
    try {
      log("--- 🏁 Memulai Pengecekan AHO untuk $transNo ---");
      final box = await Hive.openBox<ServiceCallValidationEntryModel>(
          kServiceCallHiveBox);
      final entries = box.values.where((entry) => entry.transNo == transNo);

      if (entries.isEmpty) return false;

      if (entries.isEmpty) {
        log("🔴 GAGAL: Tidak ada entri Hive ditemukan untuk $transNo");
        return false;
      }
      log("✅ Ditemukan ${entries.length} entri di Hive.");

      // Buat "peta" solusi untuk pencarian cepat
      final Map<String, Solution> solutionMap = {};
      for (var source in problemSources) {
        for (var problem in source.problems) {
          for (var solution in problem.solutions) {
            solutionMap[solution.solutionId] = solution;
          }
        }
      }

      log("✅ Peta solusi (solutionMap) dibuat dengan ${solutionMap.length} total solusi.");

      // Cek setiap entri di Hive
      for (var entry in entries) {
        log("--- 🕵️ Menganalisis Entri: ${entry.serialNo} ---");
        for (var problem in entry.problems) {
          for (var solutionId in problem.solutionIds) {
            final solution = solutionMap[solutionId];

            if (solution != null) {
              // Log paling penting ada di sini
              log("    > Mengecek SolutionID: $solutionId | Nama: ${solution.solutionName} | AHO Flag: '${solution.ahoFlag}'");

              if (solution.ahoFlag.toLowerCase().trim() == 'true') {
                // Tambahkan .trim()
                log("    🎉🎉🎉 DITEMUKAN AHO TRUE! Hentikan pencarian.");
                return true; // Ditemukan!
              }
            } else {
              // Log error jika data tidak sinkron
              log("    ⚠️ PERINGATAN: SolutionID $solutionId dari Hive tidak ditemukan di Peta Solusi (solutionMap).");
            }
          }
        }
      }

      log("--- 🛑 Selesai Pengecekan: Tidak ada AHO flag 'true' yang ditemukan. ---");
      return false; // Tidak ditemukan
    } catch (e, stacktrace) {
      log("Error checking AHO flag: $e", error: e, stackTrace: stacktrace);
      return false;
    }
  }

  Future<void> _onScFinalValidationRequested(
    ScFinalValidationRequested event,
    Emitter<ServiceCallSubmittedState> emit,
  ) async {
    emit(ScFinalValidationLoading());
    final bool needsAho = await _checkIfAhoIsNeeded(
      event.transNo,
      event.problemSources,
    );

    if (needsAho) {
      emit(ScProceedToAhoDialog(event.formState, initialAho: _cachedAhoNumber));
    } else {
      emit(ScProceedToOtpDialog(event.formState,
          ahoNumber: null));
    }
  }

  Future<void> _onAhoInputCompleted(
    AhoInputCompleted event,
    Emitter<ServiceCallSubmittedState> emit,
  ) async {
    _cachedAhoNumber = event.ahoNumber;
    // Setelah AHO diisi, baru kita lanjut ke OTP
    emit(ScProceedToOtpDialog(event.formState, ahoNumber: event.ahoNumber));
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
        transactionInfo,
        event.ahoNumber,
      );

      if (result['status'] == 'OK') {
        emit(ValidationUploadInProgress());
        final transNo = result['result']['trans_no'];
        final presignedDetail = result['result']['detail'];

        final uploadResult = await uploadAllImagesToS3(transNo, presignedDetail,
            progressCubit: event.progressCubit);

        if (uploadResult.allSuccess) {
          try {
            final response = await serviceRepo.confirmUploadSuccess(event.transNo);

            if (response['status'] == 'OK') {
              _cachedAhoNumber = '';
              await clearTransactionData(event.transNo);

              emit(ValidationSuccess(transNo: event.transNo, presignedDetail: []));
            } else {
              emit(ValidationFailure("Foto terunggah, tapi gagal update status server: ${response['message']}"));
            }
          } catch (e) {
            emit(ValidationFailure("Gagal konfirmasi status ke server: $e"));
          }
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

      if (result.allSuccess) {
        try {
          final response = await serviceRepo.confirmUploadSuccess(event.transNo);

          if (response['status'] == 'OK') {
            _cachedAhoNumber = '';
            await clearTransactionData(event.transNo);

            // Berhasil total
            emit(ValidationSuccess(
              transNo: event.transNo,
              presignedDetail: event.presignedDetail,
            ));
          } else {
            // S3 Berhasil tapi API Gagal
            emit(ValidationFailure("Foto terunggah, tapi gagal update status server: ${response['message']}"));
          }
        } catch (e) {
          emit(ValidationFailure("Gagal konfirmasi ke server: $e"));
        }
      } else {
        final cacheBox = Hive.box<Map<dynamic, dynamic>>(
            kServiceCallValidationPartialHiveBox);
        final oldData =
            Map<String, dynamic>.from(cacheBox.get(event.transNo) ?? {});
        await cacheBox.put(event.transNo, {
          ...oldData,
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

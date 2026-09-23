import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../components/upload_s3_service.dart';
import '../../../models/service_call/problem_source_model.dart';
import '../../../models/service_call_freezer/scf_info_model.dart';
import '../../../models/service_call_freezer/scf_validation_entry_model.dart';
import '../../../models/service_call_freezer/scf_validation_entry_model_ext.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';
import '../../service/service_repository.dart';
import '../../upload_progress/upload_progress_cubit.dart';
import '../scf_form/scf_form_state.dart';
import 'scf_submitted_repository.dart';

part 'scf_submitted_event.dart';
part 'scf_submitted_state.dart';

class ScfSubmittedBloc extends Bloc<ScfSubmittedEvent, ScfSubmittedState> {
  final ScfSubmittedRepository repository;
  String _cachedAhoNumber = '';
  final _serviceRepo = ServiceTaskRepository();

  ScfSubmittedBloc({required this.repository}) : super(ScfSubmittedInitial()) {
    on<ScfFinalValidationRequested>(_onFinalValidationRequested);
    on<ScfAhoInputCompleted>(_onAhoInputCompleted);
    on<SubmitScfValidation>(_onSubmit);
    on<RetryScfUpload>(_onRetry);
    on<LoadScfPartial>(_onLoadPartial);
  }

  String _key(String t) =>
      t.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  bool _isDemoTransNo(String t) =>
      t.trim().toUpperCase() == kDummyScfTransNo.trim().toUpperCase();

  // --- AHO gate (mirror SC _checkIfAhoIsNeeded) ---
  Future<bool> _checkIfAhoIsNeeded(
      String transNo, List<ProblemSourceModel> problemSources) async {
    try {
      final box = await Hive.openBox<ScfValidationEntryModel>(
          kServiceCallFreezerEntryBox);
      final tx = transNo.trim().toUpperCase();
      final entries =
          box.values.where((e) => e.transNo.trim().toUpperCase() == tx);
      if (entries.isEmpty) return false;

      final Map<String, Solution> solutionMap = {};
      for (final source in problemSources) {
        for (final problem in source.problems) {
          for (final solution in problem.solutions) {
            solutionMap[solution.solutionId] = solution;
          }
        }
      }

      for (final entry in entries) {
        for (final problem in entry.problems) {
          for (final solutionId in problem.solutionIds) {
            final solution = solutionMap[solutionId];
            if (solution != null) {
              final flag = solution.ahoFlag.toLowerCase().trim();
              if (flag == 'y' || flag == 'true') return true;
            }
          }
        }
      }
      return false;
    } catch (e, st) {
      log('Error checking SCF AHO flag: $e', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> _onFinalValidationRequested(
      ScfFinalValidationRequested event,
      Emitter<ScfSubmittedState> emit) async {
    emit(ScfFinalValidationLoading());
    final needsAho =
        await _checkIfAhoIsNeeded(event.transNo, event.problemSources);
    if (needsAho) {
      emit(ScfProceedToAhoDialog(event.formState, initialAho: _cachedAhoNumber));
    } else {
      emit(ScfProceedToOtpDialog(event.formState, ahoNumber: null));
    }
  }

  void _onAhoInputCompleted(
      ScfAhoInputCompleted event, Emitter<ScfSubmittedState> emit) {
    _cachedAhoNumber = event.ahoNumber;
    emit(ScfProceedToOtpDialog(event.formState, ahoNumber: event.ahoNumber));
  }

  // --- Submit ---
  Future<void> _onSubmit(
      SubmitScfValidation event, Emitter<ScfSubmittedState> emit) async {
    emit(ScfSubmitting());
    try {
      final entryBox = await Hive.openBox<ScfValidationEntryModel>(
          kServiceCallFreezerEntryBox);
      final infoBox =
          await Hive.openBox<ScfInfoModel>(kServiceCallFreezerInfoBox);

      final tx = event.transNo.trim().toUpperCase();
      final entries = entryBox.values
          .where((e) => e.transNo.trim().toUpperCase() == tx)
          .toList();
      if (entries.isEmpty) {
        emit(const ScfSubmitFailure('Belum ada freezer yang divalidasi.'));
        return;
      }

      // DEMO: task dummy tidak dikirim ke backend. Lewati submit API + upload
      // S3 + konfirmasi; cukup tampilkan sukses lalu bersihkan draft (entry +
      // info/PIC) agar langsung bisa dicoba input ulang.
      if (kEnableDummyDemoTasks && _isDemoTransNo(event.transNo)) {
        // Tampilkan dialog progres upload sesaat DULU lalu sukses. Handler state
        // sukses menutup dialog teratas (if canPop → pop); di demo tak ada
        // langkah upload nyata, jadi tanpa dialog progres ini pop malah menutup
        // LAYAR DETAIL dan dialog sukses muncul di context yang sudah di-pop →
        // tombol OK tak berfungsi. Emit progres dulu agar yang di-pop dialog itu.
        emit(ScfUploadInProgress());
        await _clearDrafts(event.transNo, entryBox, infoBox);
        _cachedAhoNumber = '';
        emit(ScfSubmitSuccess(event.transNo));
        return;
      }

      final info = infoBox.get(_key(event.transNo));
      final items = entries.map((e) => e.toJson()).toList();

      final result = await repository.submit(
        transNo: tx,
        createdBy: event.createdBy,
        createdByName: event.createdByName,
        createdByIp: event.createdByIP,
        pathAttachment: event.pathAttachment,
        info: info,
        items: items,
        ahoNumber: event.ahoNumber,
      );

      if (result['status'] == 'OK') {
        emit(ScfUploadInProgress());
        final detail =
            (result['result']?['detail'] as List<dynamic>?) ?? <dynamic>[];

        final uploadResult = await uploadScfImagesToS3(
          tx,
          detail,
          progressCubit: event.progressCubit,
        );

        if (uploadResult.allSuccess) {
          await _confirmTaskDone(event.transNo);
          await _clearDrafts(event.transNo, entryBox, infoBox);
          _cachedAhoNumber = '';
          emit(ScfSubmitSuccess(event.transNo));
        } else {
          final cleanFailed =
              uploadResult.failedFiles.map((f) => f.split(' (').first).toList();
          final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(
              kServiceCallFreezerPartialBox);
          await cacheBox.put(event.transNo, {
            'transNo': event.transNo,
            'failedFiles': cleanFailed,
            'presignedDetail': detail,
            'storeName': event.storeName,
            'module': kServiceCallFreezerModuleType,
          });
          emit(ScfUploadPartial(
            successCount: uploadResult.successCount,
            failureCount: uploadResult.failureCount,
            failedFiles: cleanFailed,
            transNo: event.transNo,
            presignedDetail: detail,
          ));
        }
      } else {
        emit(ScfSubmitFailure(result['message']?.toString() ?? 'Submit gagal.'));
      }
    } catch (e) {
      emit(ScfSubmitFailure(e.toString()));
    }
  }

  Future<void> _onRetry(
      RetryScfUpload event, Emitter<ScfSubmittedState> emit) async {
    emit(ScfSubmitting());
    try {
      final result = await uploadScfImagesToS3(
        event.transNo,
        event.presignedDetail,
        filter: event.failedFiles,
        progressCubit: event.progressCubit,
      );

      if (result.allSuccess) {
        await _confirmTaskDone(event.transNo);
        final entryBox = await Hive.openBox<ScfValidationEntryModel>(
            kServiceCallFreezerEntryBox);
        final infoBox =
            await Hive.openBox<ScfInfoModel>(kServiceCallFreezerInfoBox);
        await _clearDrafts(event.transNo, entryBox, infoBox);
        _cachedAhoNumber = '';
        emit(ScfSubmitSuccess(event.transNo));
      } else {
        final cacheBox =
            Hive.box<Map<dynamic, dynamic>>(kServiceCallFreezerPartialBox);
        final oldData =
            Map<String, dynamic>.from(cacheBox.get(event.transNo) ?? {});
        await cacheBox.put(event.transNo, {
          ...oldData,
          'transNo': event.transNo,
          'failedFiles': result.failedFiles,
          'presignedDetail': event.presignedDetail,
        });
        emit(ScfUploadPartial(
          successCount: result.successCount,
          failureCount: result.failureCount,
          failedFiles: result.failedFiles,
          transNo: event.transNo,
          presignedDetail: event.presignedDetail,
        ));
      }
    } catch (e) {
      emit(ScfSubmitFailure('Retry error: $e'));
    }
  }

  Future<void> _onLoadPartial(
      LoadScfPartial event, Emitter<ScfSubmittedState> emit) async {
    try {
      final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(
          kServiceCallFreezerPartialBox);
      final cached = cacheBox.get(event.transNo);
      if (cached != null) {
        final typed = Map<String, dynamic>.from(cached);
        emit(ScfUploadPartial(
          successCount: 0,
          failureCount: (typed['failedFiles'] as List?)?.length ?? 0,
          failedFiles: List<String>.from(typed['failedFiles'] ?? []),
          transNo: event.transNo,
          presignedDetail: List<dynamic>.from(typed['presignedDetail'] ?? []),
        ));
      }
    } catch (e) {
      emit(ScfSubmitFailure('Load cache error: $e'));
    }
  }

  /// Tandai task selesai di server (pola RRO/POS/SC + fix POSF confirmation-gap).
  /// confirmUploadSuccess tidak pernah throw (mengembalikan {status:ERROR} bila
  /// gagal). Bila status != OK, antrikan ke ConfirmationService agar di-retry
  /// saat startup — cegah task nyangkut di pending walau draft sudah dibersihkan.
  Future<void> _confirmTaskDone(String transNo) async {
    final confirmResponse = await _serviceRepo.confirmUploadSuccess(transNo);
    if (confirmResponse['status'] != 'OK') {
      final queueBox = Hive.isBoxOpen(kConfirmationQueueBox)
          ? Hive.box<ConfirmationTaskModel>(kConfirmationQueueBox)
          : await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
      await queueBox.put(transNo, ConfirmationTaskModel(transNo: transNo));
    }
  }

  Future<void> _clearDrafts(
    String transNo,
    Box<ScfValidationEntryModel> entryBox,
    Box<ScfInfoModel> infoBox,
  ) async {
    final tx = transNo.trim().toUpperCase();
    final keys = entryBox.keys
        .where((k) => entryBox.get(k)?.transNo.trim().toUpperCase() == tx)
        .toList();
    await entryBox.deleteAll(keys);
    await infoBox.delete(_key(transNo));
  }
}

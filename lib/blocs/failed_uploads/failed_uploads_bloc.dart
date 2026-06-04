import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/constants.dart';
import '../../components/services/hive_clear_service.dart';
import '../../components/upload_s3_service.dart';
import '../../models/installation/installation_model.dart';
import '../../models/proof_of_service/pos_unserviceable_model.dart';
import '../../models/service_call/sc_unserviceable_model.dart';
import '../../models/task_maintenance/confirmation_task_queue.dart';
import '../../models/task_maintenance/task_maintenance_model.dart';
import '../../screens/common/services/confirmation_service.dart';
import '../service/service_repository.dart';
import 'failed_uploads_repository.dart';
import '../../../models/rro_cut_off/rro_cut_off_entry_model.dart';

part 'failed_uploads_event.dart';

part 'failed_uploads_state.dart';

class FailedUploadsBloc extends Bloc<FailedUploadsEvent, FailedUploadsState> {
  final UploadProgressCubit progressCubit;
  final FailedUploadsRepository repository;
  final List<StreamSubscription> _hiveSubscriptions = [];
  final serviceRepo = ServiceTaskRepository();

  FailedUploadsBloc({
    required this.progressCubit,
    required this.repository,
  }) : super(const FailedUploadsState()) {
    on<LoadFailedUploads>(_onLoadFailedUploads);
    on<RetryTransaction>(_onRetryTransaction);
    on<ClearSnackbarMessage>(_onClearSnackbarMessage);
    on<ClearSuccessMessage>(_onClearSuccessMessage);
    on<SyncWithApiPending>(_onSyncWithApiPending);

    _listenToHiveChanges();
  }

  // --- 1. SYNC LOGIC (OPTIMASI ZOMBIE) ---
  void _onSyncWithApiPending(
      SyncWithApiPending event, Emitter<FailedUploadsState> emit) {
    final localTransNos =
        state.failedTransactions.map((t) => t['transNo'] as String).toSet();

    int zombieCount = 0;
    for (var apiTask in event.apiPendingList) {
      if (!localTransNos.contains(apiTask.transNo)) {
        zombieCount++;
      }
    }

    emit(state.copyWith(
      zombieCount: zombieCount,
      totalIssues: state.failedTransactions.length + zombieCount,
    ));
  }

  // --- 2. LOAD DATA (DIPERBARUI) ---
  Future<void> _onLoadFailedUploads(
      LoadFailedUploads event, Emitter<FailedUploadsState> emit) async {
    final bool isInitialLoad = state.status == FailedUploadsStatus.initial;
    emit(state.copyWith(
        status: FailedUploadsStatus.loading,
        clearErrorMessage: true,
        clearUploadingTransNo: isInitialLoad));

    final List<Map<String, dynamic>> allFailedTyped = [];
    try {
      Future<void> loadFromBox(String boxName, String moduleHint) async {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox<Map<dynamic, dynamic>>(boxName);
        }
        final box = Hive.box<Map<dynamic, dynamic>>(boxName);
        final values = box.values.map((map) {
          final typedMap = Map<String, dynamic>.from(map);
          typedMap.putIfAbsent('module', () => moduleHint);
          return typedMap;
        }).toList();
        allFailedTyped.addAll(values);
      }

      await loadFromBox(kPosValidationPartialHiveBox, 'POS');
      await loadFromBox(kServiceCallValidationPartialHiveBox, 'SC');
      await loadFromBox(kPosUnserviceablePartialBox, 'POS_UNSERVICEABLE');
      await loadFromBox(kScUnserviceablePartialBox, 'SC_UNSERVICEABLE');
      await loadFromBox(
          kFailedUploadsBox, 'INSTALLATION'); // RRO otomatis nebeng di sini

      emit(state.copyWith(
        status: FailedUploadsStatus.loaded,
        failedTransactions: allFailedTyped,
        totalIssues: allFailedTyped.length + state.zombieCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FailedUploadsStatus.error,
        errorMessage: "Gagal memuat data lokal: $e",
        failedTransactions: [],
      ));
    }
  }

  // --- 3. RETRY / RESET LOGIC ---
  Future<void> _onRetryTransaction(
      RetryTransaction event, Emitter<FailedUploadsState> emit) async {
    if (state.status == FailedUploadsStatus.uploading) return;

    emit(state.copyWith(
      status: FailedUploadsStatus.uploading,
      uploadingTransNo: event.transNo,
      clearSnackbarMessage: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      // === KASUS 1: ZOMBIE (RESET SERVER) ===
      if (event.isZombie) {
        await repository.resetTransactionData(event.transNo);

        final updatedList =
            List<Map<String, dynamic>>.from(state.failedTransactions)
              ..removeWhere((t) => t['transNo'] == event.transNo);

        emit(state.copyWith(
          status: FailedUploadsStatus.success,
          failedTransactions: updatedList,
          zombieCount: (state.zombieCount - 1).clamp(0, 999),
          totalIssues: (state.totalIssues - 1).clamp(0, 999),
          clearUploadingTransNo: true,
          successMessage:
              "Status transaksi ${event.transNo} berhasil di-reset.",
        ));
        return;
      }

      // === KASUS 2: NORMAL RETRY (UPLOAD S3) ===
      final transactionData = state.failedTransactions.firstWhere(
        (t) => t['transNo'] == event.transNo,
        orElse: () => {},
      );

      if (transactionData.isEmpty) {
        throw Exception("Data lokal tidak ditemukan.");
      }

      final String moduleType =
          transactionData['module']?.toString() ?? 'UNKNOWN';
      final List<String> originalFailedFiles =
          (transactionData['failedFiles'] as List<dynamic>?)?.cast<String>() ??
              [];
      final List<dynamic> presignedDetail =
          (transactionData['presignedDetail'] as List<dynamic>?) ?? [];
      final String storeName = transactionData['storeName']?.toString() ?? '';

      UploadResult result;
      if (moduleType == 'POS') {
        result = await uploadPosImagesToS3(event.transNo, presignedDetail,
            progressCubit: progressCubit, filter: originalFailedFiles);
      } else if (moduleType == 'SC') {
        result = await uploadAllImagesToS3(event.transNo, presignedDetail,
            progressCubit: progressCubit, filter: originalFailedFiles);
      } else if (moduleType == 'POS_UNSERVICEABLE') {
        if (!Hive.isBoxOpen(kPosUnserviceableDraftsBox)) {
          await Hive.openBox<PosUnserviceableModel>(kPosUnserviceableDraftsBox);
        }
        final report =
            Hive.box<PosUnserviceableModel>(kPosUnserviceableDraftsBox)
                .get(event.transNo);
        if (report == null) throw Exception("Draft tidak ditemukan.");
        result = await uploadPOSUnserviceableImagesToS3(report, presignedDetail,
            progressCubit: progressCubit, filter: originalFailedFiles);
      } else if (moduleType == 'SC_UNSERVICEABLE') {
        if (!Hive.isBoxOpen(kScUnserviceableDraftsBox)) {
          await Hive.openBox<SCUnserviceableModel>(kScUnserviceableDraftsBox);
        }
        final report = Hive.box<SCUnserviceableModel>(kScUnserviceableDraftsBox)
            .get(event.transNo);
        if (report == null) throw Exception("Draft tidak ditemukan.");
        result = await uploadSCUnserviceableImagesToS3(report, presignedDetail,
            progressCubit: progressCubit, filter: originalFailedFiles);
      } else if (moduleType == 'INSTALLATION') {
        if (!Hive.isBoxOpen(kInstallationDraftBox)) {
          await Hive.openBox<InstallationEntryModel>(kInstallationDraftBox);
        }
        final draftBox =
            Hive.box<InstallationEntryModel>(kInstallationDraftBox);
        final draft = draftBox.get(event.transNo);
        if (draft == null) throw Exception("Draft Instalasi tidak ditemukan.");

        final apiResultMock = {
          'result': {'detail': presignedDetail}
        };
        final uploadRes = await uploadInstallationFiles(
            apiResult: apiResultMock,
            progressCubit: progressCubit,
            draft: draft);
        result = UploadResult(
            successCount: uploadRes.successCount,
            failureCount: uploadRes.failureCount,
            failedFiles: uploadRes.failedFiles);
      } else if (moduleType == 'RRO_CUT_OFF') {
        final apiResultMock = {
          'result': {'detail': presignedDetail}
        };
        result = await uploadRROCutOffFiles(
            apiResult: apiResultMock,
            progressCubit: progressCubit,
            transNo: event.transNo);
      } else {
        throw Exception('Modul tidak dikenal.');
      }

      if (result.allSuccess) {
        try {
          final response =
              await serviceRepo.confirmUploadSuccess(event.transNo);

          if (response['status'] == 'OK') {
            // 1. Hapus kartu pending dari Failed Uploads Box
            String? targetBoxName = _getBoxNameForModule(moduleType);
            if (targetBoxName != null) {
              Box<Map<dynamic, dynamic>> box;
              if (Hive.isBoxOpen(targetBoxName)) {
                box = Hive.box<Map<dynamic, dynamic>>(targetBoxName);
              } else {
                box = await Hive.openBox<Map<dynamic, dynamic>>(targetBoxName);
              }
              await box.delete(event.transNo);
            }

            // 2. Khusus Installation & RRO: Hapus juga Draft Utama
            if (moduleType == 'INSTALLATION') {
              Box<InstallationEntryModel> draftBox;
              if (Hive.isBoxOpen(kInstallationDraftBox)) {
                draftBox =
                    Hive.box<InstallationEntryModel>(kInstallationDraftBox);
              } else {
                draftBox = await Hive.openBox<InstallationEntryModel>(
                    kInstallationDraftBox);
              }
              await draftBox.delete(event.transNo);
            }
            // 🔥 TAMBAHAN 2: CLEANUP DRAFT RRO 🔥
            else if (moduleType == 'RRO_CUT_OFF') {
              final draftBox = await Hive.openBox(kRROFormDraftBox);
              await draftBox.deleteAll([
                '${event.transNo}_picName',
                '${event.transNo}_picPhone',
                '${event.transNo}_picNik',
                '${event.transNo}_picPosition',
                '${event.transNo}_tech1',
                '${event.transNo}_tech2',
                '${event.transNo}_tech3',
                '${event.transNo}_storeFrontPhoto',
                '${event.transNo}_storeFrontLat',
                '${event.transNo}_storeFrontLng',
                '${event.transNo}_picPhotoPath',
                '${event.transNo}_picLat',
                '${event.transNo}_picLng'
              ]);

              final entryBox =
                  await Hive.openBox<RROCutOffEntryModel>(kRROCutOffEntryBox);
              final keysToDelete = entryBox.keys
                  .where((k) => entryBox.get(k)?.transNo == event.transNo)
                  .toList();
              await entryBox.deleteAll(keysToDelete);
            }

            await clearTransactionData(event.transNo);

            final updatedList =
                List<Map<String, dynamic>>.from(state.failedTransactions)
                  ..removeWhere((t) => t['transNo'] == event.transNo);

            emit(state.copyWith(
              status: FailedUploadsStatus.success,
              failedTransactions: updatedList,
              totalIssues: updatedList.length + state.zombieCount,
              clearUploadingTransNo: true,
              successMessage: 'Upload ulang berhasil!',
            ));
          } else {
            emit(state.copyWith(
              status: FailedUploadsStatus.loaded,
              clearUploadingTransNo: true,
              errorMessage:
                  "Foto terunggah, tapi gagal update status server: ${response['message']}",
            ));
          }
        } catch (e) {
          emit(state.copyWith(
            status: FailedUploadsStatus.loaded,
            clearUploadingTransNo: true,
            errorMessage: "Gagal konfirmasi ke server: $e",
          ));
        }
      } else {
        await _updateFailedTransactionInCache(event.transNo, moduleType,
            result.failedFiles, presignedDetail, storeName);
        add(LoadFailedUploads());
        emit(state.copyWith(
          status: FailedUploadsStatus.loaded,
          clearUploadingTransNo: true,
          snackbarMessage: "Masih ada ${result.failureCount} file gagal.",
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FailedUploadsStatus.loaded,
        clearUploadingTransNo: true,
        errorMessage: "Gagal memproses: $e",
      ));
    }
  }

  void _onClearSnackbarMessage(
      ClearSnackbarMessage event, Emitter<FailedUploadsState> emit) {
    emit(state.copyWith(clearSnackbarMessage: true, clearRetryResult: true));
  }

  void _onClearSuccessMessage(
      ClearSuccessMessage event, Emitter<FailedUploadsState> emit) {
    emit(state.copyWith(clearSuccessMessage: true, clearRetryResult: true));
  }

  void _listenToHiveChanges() async {
    final boxNames = [
      kPosValidationPartialHiveBox,
      kServiceCallValidationPartialHiveBox,
      kPosUnserviceablePartialBox,
      kScUnserviceablePartialBox,
      kFailedUploadsBox
    ];
    for (final boxName in boxNames) {
      try {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox<Map<dynamic, dynamic>>(boxName);
        }
        final box = Hive.box<Map<dynamic, dynamic>>(boxName);
        final subscription = box.watch().listen((event) {
          if (event.deleted && !isClosed) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!isClosed) add(LoadFailedUploads());
            });
          }
        });
        _hiveSubscriptions.add(subscription);
      } catch (_) {}
    }
  }

  @override
  Future<void> close() {
    for (var sub in _hiveSubscriptions) {
      sub.cancel();
    }
    _hiveSubscriptions.clear();
    return super.close();
  }

  Future<void> _updateFailedTransactionInCache(
      String transNo,
      String moduleType,
      List<String> files,
      List<dynamic> details,
      String store) async {
    String? boxName = _getBoxNameForModule(moduleType);
    if (boxName == null) return;
    try {
      final cacheBox = Hive.isBoxOpen(boxName)
          ? Hive.box<Map<dynamic, dynamic>>(boxName)
          : await Hive.openBox<Map<dynamic, dynamic>>(boxName);
      final oldData = Map<String, dynamic>.from(cacheBox.get(transNo) ?? {});
      await cacheBox.put(transNo, {
        ...oldData,
        'transNo': transNo,
        'failedFiles': files,
        'presignedDetail': details,
        'storeName': store,
        'module': moduleType,
      });
    } catch (_) {}
  }

  // 🔥 TAMBAHAN 3: KASIH TAHU BLOC LOKASI KOTAK RRO 🔥
  String? _getBoxNameForModule(String moduleType) {
    switch (moduleType) {
      case 'POS':
        return kPosValidationPartialHiveBox;
      case 'SC':
        return kServiceCallValidationPartialHiveBox;
      case 'POS_UNSERVICEABLE':
        return kPosUnserviceablePartialBox;
      case 'SC_UNSERVICEABLE':
        return kScUnserviceablePartialBox;
      case 'INSTALLATION':
      case 'RRO_CUT_OFF': // Sama dengan instalasi, disimpen di failed uploads global
        return kFailedUploadsBox;
      default:
        return null;
    }
  }

  Future<void> _addToConfirmationQueueIfNeeded(
      String transNo, String moduleType) async {
    if (moduleType == 'POS' || moduleType == 'SC') {
      try {
        final queueBox =
            await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
        final key = transNo.trim().toUpperCase();
        if (!queueBox.containsKey(key)) {
          await queueBox.put(key, ConfirmationTaskModel(transNo: key));
          await ConfirmationService().processQueue();
        }
      } catch (_) {}
    }
  }
}

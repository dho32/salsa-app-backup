import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/constants.dart';
import '../../components/services/hive_clear_service.dart';
import '../../components/upload_s3_service.dart';
import '../../models/proof_of_service/pos_unserviceable_model.dart';
import '../../models/service_call/sc_unserviceable_model.dart';
import '../../models/task_maintenance/confirmation_task_queue.dart';
import '../../screens/common/services/confirmation_service.dart';
import 'failed_uploads_repository.dart';

part 'failed_uploads_event.dart';
part 'failed_uploads_state.dart';

class FailedUploadsBloc extends Bloc<FailedUploadsEvent, FailedUploadsState> {
  final UploadProgressCubit progressCubit;
  final FailedUploadsRepository repository; // 🔥 Wajib ada
  final List<StreamSubscription> _hiveSubscriptions = [];

  FailedUploadsBloc({
    required this.progressCubit,
    required this.repository,
  }) : super(const FailedUploadsState()) {
    on<LoadFailedUploads>(_onLoadFailedUploads);
    on<RetryTransaction>(_onRetryTransaction); // Handler baru
    on<ClearSnackbarMessage>(_onClearSnackbarMessage);
    on<ClearSuccessMessage>(_onClearSuccessMessage);
    _listenToHiveChanges();
  }

  // --- 1. LOAD DATA (TETAP SAMA) ---
  Future<void> _onLoadFailedUploads(
      LoadFailedUploads event, Emitter<FailedUploadsState> emit) async {
    final bool isInitialLoad = state.status == FailedUploadsStatus.initial;
    emit(state.copyWith(
        status: FailedUploadsStatus.loading,
        clearErrorMessage: true,
        clearUploadingTransNo: isInitialLoad
    ));

    final List<Map<String, dynamic>> allFailedTyped = [];
    try {
      Future<void> loadFromBox(String boxName, String moduleHint) async {
        if (!Hive.isBoxOpen(boxName)) await Hive.openBox<Map<dynamic, dynamic>>(boxName);
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

      emit(state.copyWith(
        status: FailedUploadsStatus.loaded,
        failedTransactions: allFailedTyped,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FailedUploadsStatus.error,
        errorMessage: "Gagal memuat data lokal: $e",
        failedTransactions: [],
      ));
    }
  }

  // --- 2. LOGIC RETRY / RESET (INTI PERUBAHAN) ---
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
      // === KASUS 1: ZOMBIE (TIDAK MATCH) -> RESET SERVER ===
      if (event.isZombie) {
        await repository.resetTransactionData(event.transNo);

        // Hapus dari list UI
        final updatedList = List<Map<String, dynamic>>.from(state.failedTransactions)
          ..removeWhere((t) => t['transNo'] == event.transNo);

        emit(state.copyWith(
          status: FailedUploadsStatus.success,
          failedTransactions: updatedList,
          clearUploadingTransNo: true,
          successMessage: "Status transaksi ${event.transNo} berhasil di-reset.",
        ));
        return;
      }

      // === KASUS 2: MATCH (ADA DI HIVE) -> UPLOAD S3 (Logic Lama) ===

      // Ambil data detail dari Hive (Local State)
      final transactionData = state.failedTransactions.firstWhere(
            (t) => t['transNo'] == event.transNo,
        orElse: () => {},
      );

      if (transactionData.isEmpty) throw Exception("Data lokal tidak ditemukan untuk upload ulang.");

      final String moduleType = transactionData['module']?.toString() ?? 'UNKNOWN';
      final List<String> originalFailedFiles = (transactionData['failedFiles'] as List<dynamic>?)?.cast<String>() ?? [];
      final List<dynamic> presignedDetail = (transactionData['presignedDetail'] as List<dynamic>?) ?? [];
      final String storeName = transactionData['storeName']?.toString() ?? '';

      // Eksekusi Service Upload S3 Lama
      UploadResult result;
      if (moduleType == 'POS') {
        result = await uploadPosImagesToS3(event.transNo, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles);
      } else if (moduleType == 'SC') {
        result = await uploadAllImagesToS3(event.transNo, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles);
      } else if (moduleType == 'POS_UNSERVICEABLE') {
        if (!Hive.isBoxOpen(kPosUnserviceableDraftsBox)) await Hive.openBox<PosUnserviceableModel>(kPosUnserviceableDraftsBox);
        final report = Hive.box<PosUnserviceableModel>(kPosUnserviceableDraftsBox).get(event.transNo);
        if (report == null) throw Exception("Draft POS tidak ditemukan.");
        result = await uploadPOSUnserviceableImagesToS3(report, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles);
      } else if (moduleType == 'SC_UNSERVICEABLE') {
        if (!Hive.isBoxOpen(kScUnserviceableDraftsBox)) await Hive.openBox<SCUnserviceableModel>(kScUnserviceableDraftsBox);
        final report = Hive.box<SCUnserviceableModel>(kScUnserviceableDraftsBox).get(event.transNo);
        if (report == null) throw Exception("Draft SC tidak ditemukan.");
        result = await uploadSCUnserviceableImagesToS3(report, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles);
      } else {
        throw Exception('Tipe modul $moduleType tidak dikenali.');
      }

      // Handle Hasil Upload
      if (result.allSuccess) {
        await clearTransactionData(event.transNo);
        await _addToConfirmationQueueIfNeeded(event.transNo, moduleType);

        final updatedList = List<Map<String, dynamic>>.from(state.failedTransactions)
          ..removeWhere((t) => t['transNo'] == event.transNo);

        emit(state.copyWith(
          status: FailedUploadsStatus.success,
          failedTransactions: updatedList,
          uploadingTransNo: null,
          successMessage: 'Upload ulang berhasil!',
        ));
      } else {
        // Update sisa file gagal di Hive
        await _updateFailedTransactionInCache(event.transNo, moduleType, result.failedFiles, presignedDetail, storeName);

        add(LoadFailedUploads()); // Refresh list

        emit(state.copyWith(
          status: FailedUploadsStatus.loaded,
          uploadingTransNo: null,
          snackbarMessage: "Masih ada ${result.failureCount} file gagal.",
        ));
      }

    } catch (e) {
      emit(state.copyWith(
        status: FailedUploadsStatus.loaded,
        uploadingTransNo: null,
        errorMessage: "Gagal memproses: $e",
      ));
    }
  }

  // --- HELPER FUNCTIONS (Sama seperti lama) ---
  void _onClearSnackbarMessage(ClearSnackbarMessage event, Emitter<FailedUploadsState> emit) {
    emit(state.copyWith(clearSnackbarMessage: true, clearRetryResult: true));
  }
  void _onClearSuccessMessage(ClearSuccessMessage event, Emitter<FailedUploadsState> emit) {
    emit(state.copyWith(clearSuccessMessage: true, clearRetryResult: true));
  }

  void _listenToHiveChanges() async {
    final boxNames = [kPosValidationPartialHiveBox, kServiceCallValidationPartialHiveBox, kPosUnserviceablePartialBox, kScUnserviceablePartialBox];
    for (final boxName in boxNames) {
      try {
        if (!Hive.isBoxOpen(boxName)) await Hive.openBox<Map<dynamic, dynamic>>(boxName);
        final box = Hive.box<Map<dynamic, dynamic>>(boxName);
        final subscription = box.watch().listen((event) {
          if (event.deleted && !isClosed) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!isClosed) add(LoadFailedUploads());
            });
          }
        });
        _hiveSubscriptions.add(subscription);
      } catch (e) { print("Error hive listener: $e"); }
    }
  }

  @override
  Future<void> close() {
    for (var sub in _hiveSubscriptions) sub.cancel();
    _hiveSubscriptions.clear();
    return super.close();
  }

  // Hive Helpers
  Future<void> _updateFailedTransactionInCache(String transNo, String moduleType, List<String> files, List<dynamic> details, String store) async {
    String? boxName = _getBoxNameForModule(moduleType);
    if (boxName == null) return;
    try {
      final cacheBox = Hive.isBoxOpen(boxName) ? Hive.box<Map<dynamic, dynamic>>(boxName) : await Hive.openBox<Map<dynamic, dynamic>>(boxName);
      final oldData = Map<String, dynamic>.from(cacheBox.get(transNo) ?? {});
      await cacheBox.put(transNo, {
        ...oldData, 'transNo': transNo, 'failedFiles': files, 'presignedDetail': details, 'storeName': store, 'module': moduleType,
      });
    } catch (e) { print("Error update cache: $e"); }
  }

  String? _getBoxNameForModule(String moduleType) {
    switch (moduleType) {
      case 'POS': return kPosValidationPartialHiveBox;
      case 'SC': return kServiceCallValidationPartialHiveBox;
      case 'POS_UNSERVICEABLE': return kPosUnserviceablePartialBox;
      case 'SC_UNSERVICEABLE': return kScUnserviceablePartialBox;
      default: return null;
    }
  }

  Future<void> _addToConfirmationQueueIfNeeded(String transNo, String moduleType) async {
    if (moduleType == 'POS' || moduleType == 'SC') {
      try {
        final queueBox = await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
        final key = transNo.trim().toUpperCase();
        if (!queueBox.containsKey(key)) {
          await queueBox.put(key, ConfirmationTaskModel(transNo: key));
          await ConfirmationService().processQueue();
        }
      } catch (e) { print("Error queue: $e"); }
    }
  }
}
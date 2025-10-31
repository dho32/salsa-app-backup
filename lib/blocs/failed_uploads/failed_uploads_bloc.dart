import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/constants.dart';
import '../../components/services/hive_clear_service.dart'; // Pastikan import ini benar
import '../../components/upload_s3_service.dart';
import '../../models/proof_of_service/pos_unserviceable_model.dart';
import '../../models/service_call/sc_unserviceable_model.dart';
import '../../models/task_maintenance/confirmation_task_queue.dart';

part 'failed_uploads_event.dart'; // Pastikan event FinalizeSuccessfulRetry ada di sini
part 'failed_uploads_state.dart'; // Pastikan state punya field retry...


class FailedUploadsBloc extends Bloc<FailedUploadsEvent, FailedUploadsState> {
  final UploadProgressCubit progressCubit;
  final List<StreamSubscription> _hiveSubscriptions = [];

  FailedUploadsBloc({
    required this.progressCubit,
  }) : super(const FailedUploadsState()) {
    on<LoadFailedUploads>(_onLoadFailedUploads);
    on<RetrySingleFailedUpload>(_onRetrySingleFailedUpload);
    on<ClearSnackbarMessage>(_onClearSnackbarMessage);
    on<ClearSuccessMessage>(_onClearSuccessMessage);
    _listenToHiveChanges();
  }

  void _listenToHiveChanges() async {
    final boxNames = [
      kPosValidationPartialHiveBox,
      kServiceCallValidationPartialHiveBox,
      kPosUnserviceablePartialBox,
      kScUnserviceablePartialBox,
    ];

    for (final boxName in boxNames) {
      try {
        final box = await Hive.openBox<Map<dynamic, dynamic>>(boxName);
        final subscription = box.watch().listen((event) {
          // Hanya trigger reload jika ada data yg dihapus (untuk mengurangi loop)
          if (event.deleted) {

            print("📦 Hive DELETION detected in $boxName for key ${event.key}, scheduling reload...");
            if (!isClosed) {
              // Tambahkan delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!isClosed) {
                  // HAPUS DELAY: Langsung add event
                  add(LoadFailedUploads());
                }
              });
            }
          }
        });
        _hiveSubscriptions.add(subscription);
      } catch (e) {
        print("🔴 Error setting up Hive listener for $boxName: $e");
      }
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

  Future<void> _onLoadFailedUploads(
      LoadFailedUploads event, Emitter<FailedUploadsState> emit) async {
    // Pastikan reset uploadingTransNo hanya saat loading awal, bukan saat refresh
    final bool isInitialLoad = state.status == FailedUploadsStatus.initial || state.status == FailedUploadsStatus.loading;
    emit(state.copyWith(
        status: FailedUploadsStatus.loading,
        clearErrorMessage: true,
        // Reset uploadingTransNo hanya jika ini BUKAN refresh karena watch()
        clearUploadingTransNo: isInitialLoad
    ));

    final List<Map<String, dynamic>> allFailedTyped = [];
    try {
      print("🔄 Loading failed uploads...");

      Future<void> loadFromBox(String boxName, String moduleHint) async {
        Box<Map<dynamic, dynamic>>? box; // Deklarasi box nullable
        try {
          // 1. Coba akses via Hive.box() dulu (asumsi sudah dibuka di main)
          if (Hive.isBoxOpen(boxName)) {
            box = Hive.box<Map<dynamic, dynamic>>(boxName);
            print("  [Loader] Accessed open box: $boxName");
          } else {
            // 2. Jika belum terbuka, coba buka SEKARANG (fallback)
            print("  [Loader] Box $boxName not open, attempting to open...");
            box = await Hive.openBox<Map<dynamic, dynamic>>(boxName);
            print("  [Loader] Successfully opened box: $boxName");
          }

          // 3. Jika box berhasil didapatkan/dibuka, baca datanya
          final values = box.values.map((map) {
            final typedMap = Map<String, dynamic>.from(map);
            typedMap.putIfAbsent('module', () => moduleHint);
            return typedMap;
          }).toList();
          allFailedTyped.addAll(values);
          print("  - Found ${values.length} items in $boxName.");

        } catch (e) {
          // Tangani error saat mencoba membuka atau membaca
          print("🔴 Error accessing/reading from $boxName: $e");
          // Tidak perlu throw, cukup log error dan lanjutkan ke box berikutnya
        }
      }

      await loadFromBox(kPosValidationPartialHiveBox, 'POS');
      await loadFromBox(kServiceCallValidationPartialHiveBox, 'SC');
      await loadFromBox(kPosUnserviceablePartialBox, 'POS_UNSERVICEABLE');
      await loadFromBox(kScUnserviceablePartialBox, 'SC_UNSERVICEABLE');

      print("✅ Loaded ${allFailedTyped.length} total failed transactions.");
      emit(state.copyWith(
        status: FailedUploadsStatus.loaded,
        failedTransactions: allFailedTyped,
      ));
    } catch (e) {
      print("🔴 Gagal load failed uploads: $e");
      emit(state.copyWith(
        status: FailedUploadsStatus.error,
        errorMessage: "Gagal memuat daftar upload gagal: ${e.toString()}",
        failedTransactions: [],
      ));
    }
  }

  Future<void> _onRetrySingleFailedUpload(
      RetrySingleFailedUpload event, Emitter<FailedUploadsState> emit) async {
    final transactionData = event.transactionData;
    final String transNo = transactionData['transNo']?.toString() ?? 'UNKNOWN_TRANSNO';
    final List<String> originalFailedFiles = (transactionData['failedFiles'] as List<dynamic>?)?.cast<String>() ?? [];
    final List<dynamic> presignedDetail = (transactionData['presignedDetail'] as List<dynamic>?) ?? [];
    final String moduleType = transactionData['module']?.toString() ?? 'UNKNOWN';
    final String storeName = transactionData['storeName']?.toString() ?? 'Nama Toko Tidak Tersedia';

    if (transNo == 'UNKNOWN_TRANSNO' || moduleType == 'UNKNOWN' || originalFailedFiles.isEmpty || presignedDetail.isEmpty) {
      emit(state.copyWith(
          snackbarMessage: "Data tidak lengkap untuk mencoba upload ulang $transNo.",
          status: FailedUploadsStatus.loaded, clearUploadingTransNo: true
      ));
      return;
    }

    emit(state.copyWith(
      status: FailedUploadsStatus.uploading,
      uploadingTransNo: transNo,
      clearSnackbarMessage: true, clearSuccessMessage: true, clearErrorMessage: true, clearRetryResult: true,
    ));

    try {
      UploadResult result;

      if (moduleType == 'POS') {
        result = await uploadPosImagesToS3( transNo, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles );
      } else if (moduleType == 'SC') {
        result = await uploadAllImagesToS3( transNo, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles );
      } else if (moduleType == 'POS_UNSERVICEABLE') {
        final draftBox = Hive.box<PosUnserviceableModel>(kPosUnserviceableDraftsBox); // Gunakan Hive.box()
        final report = draftBox.get(transNo);
        if (report == null) throw Exception("Draft POS Unserviceable $transNo tidak ditemukan.");
        result = await uploadPOSUnserviceableImagesToS3( report, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles );
      } else if (moduleType == 'SC_UNSERVICEABLE') {
        final draftBox = Hive.box<SCUnserviceableModel>(kScUnserviceableDraftsBox); // Gunakan Hive.box()
        final report = draftBox.get(transNo);
        if (report == null) throw Exception("Draft SC Unserviceable $transNo tidak ditemukan.");
        result = await uploadSCUnserviceableImagesToS3( report, presignedDetail, progressCubit: progressCubit, filter: originalFailedFiles );
      }
      else { throw Exception('Tipe modul tidak dikenali untuk retry.'); }

      if (result.allSuccess) {
        print("✅ Retry successful for $transNo. Melakukan cleanup SEKARANG.");

        await clearTransactionData(transNo); // Panggil helper cleanup lengkap

        // 2. Tambahkan ke queue SEKARANG
        await _addToConfirmationQueueIfNeeded(transNo, moduleType);

        final List<Map<String, dynamic>> updatedList = List.from(state.failedTransactions)
          ..removeWhere((t) => t['transNo'] == transNo);

        emit(state.copyWith(
          status: FailedUploadsStatus.loaded,
          failedTransactions: updatedList,
          clearUploadingTransNo: true,
          successMessage: 'Upload ulang untuk $transNo berhasil!',
          retrySuccessCount: originalFailedFiles.length,
          retryFailureCount: 0,
          retryFailedFiles: [],
        ));
        // Jangan tambah ke queue di sini

      } else {
        final bool allMissing = result.failedFiles.isNotEmpty && result.failedFiles.every((f) => f.startsWith("[MISSING]"));
        String snackbarMsg;

        if (allMissing) {
          print("⚠️ All files for retry ($transNo) are missing. Removing item from partial cache ONLY.");
          snackbarMsg = "File foto untuk $transNo tidak ditemukan di perangkat.";
          // Hapus HANYA dari cache partial
          await _removeFailedTransactionFromCache(transNo, moduleType);

          // Hapus dari list state saat ini
          final List<Map<String, dynamic>> updatedList = List.from(state.failedTransactions)
            ..removeWhere((t) => t['transNo'] == transNo);

          emit(state.copyWith(
            status: FailedUploadsStatus.loaded,
            failedTransactions: updatedList, // Emit list yg sudah diupdate
            clearUploadingTransNo: true,
            snackbarMessage: snackbarMsg,
            retrySuccessCount: 0,
            retryFailureCount: originalFailedFiles.length,
            retryFailedFiles: result.failedFiles,
          ));
        } else {
          print("⚠️ Retry partially failed for $transNo");
          await _updateFailedTransactionInCache( transNo, moduleType, result.failedFiles, presignedDetail, storeName);

          final List<Map<String, dynamic>> updatedList = state.failedTransactions.map((t) {
            final typedT = Map<String, dynamic>.from(t);
            if (typedT['transNo'] == transNo) {
              return Map<String, dynamic>.from(typedT)..['failedFiles'] = result.failedFiles;
            }
            return typedT;
          }).toList();

          snackbarMsg = "Masih ada ${result.failureCount} file gagal untuk $transNo.";
          emit(state.copyWith(
            status: FailedUploadsStatus.loaded,
            failedTransactions: updatedList,
            clearUploadingTransNo: true,
            snackbarMessage: snackbarMsg,
            retrySuccessCount: result.successCount,
            retryFailureCount: result.failureCount,
            retryFailedFiles: result.failedFiles,
          ));
        }
      }

    } catch (e) {
      print("🔴 Retry failed with exception for $transNo: $e");
      emit(state.copyWith(
        status: FailedUploadsStatus.loaded,
        clearUploadingTransNo: true,
        snackbarMessage: "Gagal mencoba upload ulang untuk $transNo: ${e.toString()}",
        retrySuccessCount: 0,
        retryFailureCount: originalFailedFiles.length,
        retryFailedFiles: originalFailedFiles.map((f) => "$f (Exception)").toList(),
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


  // --- Helper Functions ---
  Future<void> _removeFailedTransactionFromCache(String transNo, String moduleType) async {
    String? boxName = _getBoxNameForModule(moduleType);
    if (boxName == null) { print("🔴 Cannot remove from cache: Unknown box name for module $moduleType"); return; }
    try {
      final cacheBox = Hive.box<Map<dynamic, dynamic>>(boxName); // Gunakan Hive.box()
      await cacheBox.delete(transNo);
      print("🗑️ Removed $transNo ($moduleType) from cache box $boxName.");
    } catch (e) { print("🔴 Error removing $transNo from cache box $boxName: $e"); }
  }

  Future<void> _updateFailedTransactionInCache(String transNo, String moduleType, List<String> remainingFailedFiles, List<dynamic> presignedDetail, String storeName) async {
    String? boxName = _getBoxNameForModule(moduleType);
    if (boxName == null) { print("🔴 Cannot update cache: Unknown box name for module $moduleType"); return; }
    try {
      final cacheBox = Hive.box<Map<dynamic, dynamic>>(boxName); // Gunakan Hive.box()
      final oldData = Map<String, dynamic>.from(cacheBox.get(transNo) ?? {});
      await cacheBox.put(transNo, {
        ...oldData,
        'transNo': transNo,
        'failedFiles': remainingFailedFiles,
        'presignedDetail': presignedDetail,
        'storeName': storeName,
        'module': moduleType,
      });
      print("💾 Updated cache for $transNo ($moduleType) in box $boxName.");
    } catch (e) { print("🔴 Error updating cache for $transNo in box $boxName: $e"); }
  }

  String? _getBoxNameForModule(String moduleType) {
    switch (moduleType) {
      case 'POS': return kPosValidationPartialHiveBox;
      case 'SC': return kServiceCallValidationPartialHiveBox;
      case 'POS_UNSERVICEABLE': return kPosUnserviceablePartialBox;
      case 'SC_UNSERVICEABLE': return kScUnserviceablePartialBox;
      default:
        print("🔴 Unknown module type in _getBoxNameForModule: $moduleType");
        return null;
    }
  }

  Future<void> _addToConfirmationQueueIfNeeded(String transNo, String moduleType) async {
    if (moduleType == 'POS' || moduleType == 'SC') {
      try {
        final queueBox = Hive.box<ConfirmationTaskModel>(kConfirmationQueueBox); // Gunakan Hive.box()
        final key = transNo.trim().toUpperCase();
        if (!queueBox.containsKey(key)) {
          final task = ConfirmationTaskModel(transNo: key);
          await queueBox.put(key, task);
          print("✅ Added $key ($moduleType) to confirmation queue after successful retry.");
        } else {
          print("ℹ️ $key ($moduleType) already in confirmation queue.");
        }
      } catch (e) { print("🔴 Error adding $transNo to confirmation queue: $e"); }
    }
  }

}
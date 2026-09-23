import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/blocs/service/service_repository.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/services/photo_capture_service.dart';
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/components/upload_s3_service.dart' hide getHiveKeyForTransaction;
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/proof_of_service_freezer/proof_of_service_freezer_entry_model.dart';
import 'package:salsa/models/task_maintenance/confirmation_task_queue.dart';
import 'package:salsa/models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';
import 'package:salsa/models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';

import 'posf_closed_repository.dart';

part 'posf_closed_event.dart';
part 'posf_closed_state.dart';

/// Alur "Freezer Tidak Bisa Diservis" (close). Pola POS report-issue, tapi:
/// - payload `proof_images` = filename string (sesuai `[]string` backend),
/// - foto bukti di-hold di state (tanpa Hive draft model),
/// - bila sebagian foto gagal naik S3, partial dipersist ke
///   `kProofOfServiceFreezerClosedPartialBox` (path foto + presigned) lalu
///   di-retry background oleh failed_uploads_bloc saat startup.
class PosfClosedBloc extends Bloc<PosfClosedEvent, PosfClosedState> {
  final String transNo;
  final PosfClosedRepository _repository;

  static const int maxProofPhotos = 3;

  PosfClosedBloc({required this.transNo, PosfClosedRepository? repository})
      : _repository = repository ?? PosfClosedRepository(),
        super(const PosfClosedState()) {
    on<TakeClosedProofPhoto>(_onTakePhoto);
    on<RemoveClosedProofPhoto>(_onRemovePhoto);
    on<ClosedReasonSelected>(_onReasonSelected);
    on<ClosedNotesChanged>(_onNotesChanged);
    on<SubmitClosedReport>(_onSubmit);
  }

  bool _isDemoTransNo(String t) =>
      t.trim().toUpperCase() == kDummyPosfTransNo.trim().toUpperCase();

  Future<void> _onTakePhoto(
      TakeClosedProofPhoto event, Emitter<PosfClosedState> emit) async {
    if (state.status == PosfClosedStatus.loading) return;
    if (state.proofImages.length >= maxProofPhotos) return;

    emit(state.copyWith(status: PosfClosedStatus.loading));
    try {
      final img = await captureWatermarkedPhoto(transNo,
          photoLabel: 'Bukti Tidak Bisa Service', storeName: _storeName());
      if (img == null) {
        emit(state.copyWith(status: PosfClosedStatus.initial));
        return;
      }
      final updated = List<CapturedImageDetail>.from(state.proofImages)
        ..add(img);
      emit(state.copyWith(
          proofImages: updated, status: PosfClosedStatus.initial));
    } catch (e) {
      emit(state.copyWith(
          status: PosfClosedStatus.failure,
          errorMessage: 'Gagal mengambil foto: $e'));
      await Future.delayed(const Duration(milliseconds: 300));
      emit(state.copyWith(status: PosfClosedStatus.initial));
    }
  }

  void _onRemovePhoto(
      RemoveClosedProofPhoto event, Emitter<PosfClosedState> emit) {
    final updated = List<CapturedImageDetail>.from(state.proofImages)
      ..remove(event.photo);
    emit(state.copyWith(proofImages: updated));
  }

  void _onReasonSelected(
      ClosedReasonSelected event, Emitter<PosfClosedState> emit) {
    emit(state.copyWith(selectedReason: event.reason, clearPartial: true));
  }

  void _onNotesChanged(
      ClosedNotesChanged event, Emitter<PosfClosedState> emit) {
    emit(state.copyWith(notes: event.notes, clearPartial: true));
  }

  Future<void> _onSubmit(
      SubmitClosedReport event, Emitter<PosfClosedState> emit) async {
    if (state.proofImages.isEmpty || state.selectedReason == null) {
      emit(state.copyWith(
          status: PosfClosedStatus.failure,
          errorMessage: 'Alasan dan minimal 1 foto bukti wajib diisi.'));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(status: PosfClosedStatus.initial));
      return;
    }

    emit(state.copyWith(status: PosfClosedStatus.loading));
    try {
      // DEMO: task dummy tidak dikirim ke backend. Lewati submit API + upload
      // S3 + konfirmasi; cukup tampilkan sukses lalu bersihkan draft freezer
      // agar langsung bisa dicoba input ulang. Emit uploading DULU (menampilkan
      // dialog progres) supaya dialog sukses mem-pop dialog itu, bukan layar.
      if (kEnableDummyDemoTasks && _isDemoTransNo(transNo)) {
        emit(state.copyWith(status: PosfClosedStatus.uploading));
        await _clearFreezerDrafts();
        emit(state.copyWith(status: PosfClosedStatus.success));
        return;
      }

      final user = await AuthStorage.getUser();
      final fileNames =
          state.proofImages.map((e) => e.imagePath.split('/').last).toList();

      final result = await _repository.submitClosed(
        transNo: transNo,
        reason: state.selectedReason!,
        notes: state.notes,
        reportedBy: user['name'] ?? '',
        reportedById: user['user_id'] ?? '',
        proofImageFileNames: fileNames,
      );

      if (result['status'] == 'OK') {
        emit(state.copyWith(status: PosfClosedStatus.uploading));
        final detailList =
            (result['result']?['detail'] as List<dynamic>?) ?? <dynamic>[];

        final uploadResult = await uploadProofOfServiceFreezerClosedImagesToS3(
          state.proofImages,
          detailList,
          progressCubit: event.progressCubit,
        );

        if (uploadResult.allSuccess) {
          await _confirmTaskDone();
          await _clearClosePartial();
          await _clearFreezerDrafts();
          emit(state.copyWith(status: PosfClosedStatus.success));
        } else {
          final cleanFailed =
              uploadResult.failedFiles.map((f) => f.split(' (').first).toList();
          // Persist partial → failed_uploads_bloc me-retry di background (foto
          // bukti close hanya ada di disk, path-nya disimpan di partial box).
          await _persistClosePartial(detailList, cleanFailed);
          emit(state.copyWith(
            status: PosfClosedStatus.partialFailure,
            presignedDetail: detailList,
            failedFiles: cleanFailed,
            successCount: uploadResult.successCount,
            failureCount: uploadResult.failureCount,
          ));
        }
      } else {
        throw Exception(result['message'] ?? 'Gagal mengirim laporan.');
      }
    } catch (e) {
      emit(state.copyWith(
          status: PosfClosedStatus.failure,
          errorMessage: 'Terjadi error: $e'));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: PosfClosedStatus.initial));
    }
  }

  /// Tandai task selesai di server (pola RRO/POS/SC). confirmUploadSuccess tidak
  /// pernah throw (mengembalikan {status:ERROR} bila gagal). Bila status != OK,
  /// antrikan ke ConfirmationService agar di-retry saat startup — cegah task
  /// nyangkut di pending walau draft sudah dibersihkan.
  Future<void> _confirmTaskDone() async {
    final confirmResponse =
        await ServiceTaskRepository().confirmUploadSuccess(transNo);
    if (confirmResponse['status'] != 'OK') {
      final queueBox = Hive.isBoxOpen(kConfirmationQueueBox)
          ? Hive.box<ConfirmationTaskModel>(kConfirmationQueueBox)
          : await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
      await queueBox.put(transNo, ConfirmationTaskModel(transNo: transNo));
    }
  }

  /// Setelah kunjungan ditutup (tidak bisa diservis), bersihkan draft freezer
  /// (per-unit + info transaksi) agar task ter-reset. Defensif: kegagalan
  /// pembersihan tidak menggagalkan status success.
  Future<void> _clearFreezerDrafts() async {
    try {
      final tx = transNo.trim().toUpperCase();
      if (Hive.isBoxOpen(kProofOfServiceFreezerEntryBox)) {
        final entryBox = Hive.box<ProofOfServiceFreezerEntryModel>(
            kProofOfServiceFreezerEntryBox);
        final keys = entryBox.keys
            .where((k) => entryBox.get(k)?.transNo.trim().toUpperCase() == tx)
            .toList();
        await entryBox.deleteAll(keys);
      }
      if (Hive.isBoxOpen(kProofOfServiceFreezerInfoBox)) {
        final infoBox = Hive.box<ProofOfServiceFreezerInfoModel>(
            kProofOfServiceFreezerInfoBox);
        await infoBox.delete(getHiveKeyForTransaction(transNo));
      }
    } catch (e) {
      log('Gagal membersihkan draft freezer setelah close: $e');
    }
  }

  /// Simpan partial upload foto bukti close ke box → di-retry background oleh
  /// failed_uploads_bloc (modul CUCI_FREEZER_CLOSED). Path foto dipersist karena
  /// foto bukti close tak tersimpan di Hive box entry/info (hanya di disk).
  Future<void> _persistClosePartial(
      List<dynamic> presignedDetail, List<String> failedFiles) async {
    try {
      final box = Hive.isBoxOpen(kProofOfServiceFreezerClosedPartialBox)
          ? Hive.box<Map<dynamic, dynamic>>(
              kProofOfServiceFreezerClosedPartialBox)
          : await Hive.openBox<Map<dynamic, dynamic>>(
              kProofOfServiceFreezerClosedPartialBox);
      await box.put(transNo, {
        'transNo': transNo,
        'failedFiles': failedFiles,
        'presignedDetail': presignedDetail,
        'proofImagePaths': state.proofImages.map((e) => e.imagePath).toList(),
        'storeName': _storeName(),
        'module': kProofOfServiceFreezerClosedModuleType,
      });
    } catch (e) {
      log('Gagal simpan partial close freezer: $e');
    }
  }

  Future<void> _clearClosePartial() async {
    try {
      if (Hive.isBoxOpen(kProofOfServiceFreezerClosedPartialBox)) {
        await Hive.box<Map<dynamic, dynamic>>(
                kProofOfServiceFreezerClosedPartialBox)
            .delete(transNo);
      }
    } catch (_) {}
  }

  String _storeName() {
    try {
      if (Hive.isBoxOpen(kProofOfServiceFreezerDetailBox)) {
        final hdr = Hive.box<ProofOfServiceFreezerDetailModel>(
                kProofOfServiceFreezerDetailBox)
            .get(transNo.trim().toUpperCase())
            ?.header;
        return storeTag(hdr?.shipToName, hdr?.shipTo);
      }
    } catch (_) {}
    return '';
  }
}

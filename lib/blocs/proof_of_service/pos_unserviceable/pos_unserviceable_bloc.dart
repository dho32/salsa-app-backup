import 'dart:io';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import '../../../components/services/hive_clear_service.dart';
import '../../../components/services/watermark_service.dart';
import '../../../components/upload_s3_service.dart';
import '../../../models/proof_of_service/pos_unserviceable_model.dart';
import '../../../models/proof_of_service/proof_of_service_detail_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';
import '../../../screens/common/services/confirmation_service.dart';
import '../../service/service_repository.dart';
import 'pos_unserviceable_event.dart';
import 'pos_unserviceable_repository.dart';
import 'pos_unserviceable_state.dart';

class PosUnserviceableBloc
    extends Bloc<PosUnserviceableEvent, PosUnserviceableState> {
  final String transNo;
  final Box<PosUnserviceableModel> _draftBox;
  final PosUnserviceableRepository _repository;
  late final String _userType;
  late final String _userName;
  final serviceRepo = ServiceTaskRepository();

  PosUnserviceableBloc({required this.transNo})
      : _draftBox = Hive.box<PosUnserviceableModel>(kPosUnserviceableDraftsBox),
        _repository = PosUnserviceableRepository(),
        super(const PosUnserviceableState()) {
    on<LoadUnserviceableDraft>(_onLoadInitialData);
    on<TakeProofPhoto>(_onTakeProofPhoto);
    on<RemoveProofPhoto>(_onRemoveProofPhoto);
    on<ReasonSelected>(_onReasonSelected);
    on<NotesChanged>(_onNotesChanged);
    on<TechnicianNameChanged>(_onTechnicianNameChanged);
    on<SubmitUnserviceableReport>(_onSubmitReport);
    on<RetryUnserviceableUpload>(_onRetryUpload);

    stream
        .where((state) => state.status == UnserviceableStatus.initial)
        .listen((state) {
      _saveDraftToHive(state);
    });

    _initAsync();
  }

  Future<void> _initAsync() async {
    // 1. Ambil data user dari AuthStorage
    final userData = await AuthStorage.getUser();
    _userType = userData['maintenance_type'] ?? 'WH'; // (Default 'WH')
    _userName = userData['name'] ?? '';

    // 2. Baru panggil load data DENGAN data user
    add(LoadUnserviceableDraft());
  }

  Future<void> _onLoadInitialData(
      LoadUnserviceableDraft event, Emitter<PosUnserviceableState> emit) async {
    final retryBox =
        await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
    final retryData = retryBox.get(transNo);

    if (retryData != null) {
      final dataMap = Map<String, dynamic>.from(retryData);
      // Jika ada data retry, langsung emit state partialFailure
      if (dataMap['type'] == 'unserviceable') {
        emit(state.copyWith(
          status: UnserviceableStatus.partialFailure,
          partialUploadData: dataMap,
        ));
        return; // Hentikan proses agar tidak load draft
      }
    }

    try {
      final initialDraft = _draftBox.get(transNo);
      if (initialDraft != null) {
        // 'emit' sekarang valid karena berada di dalam event handler
        emit(PosUnserviceableState(
          proofImages: initialDraft.proofImages,
          selectedReason:
              initialDraft.reason.isNotEmpty ? initialDraft.reason : null,
          notes: initialDraft.notes ?? '',
          technicianName: initialDraft.technicianName,
        ));
      } else {
        String initialTechnician1 = '';
        if (_userType == 'WH') {
          initialTechnician1 = _userName; // Otomatis isi jika 'WH'
        }
        emit(state.copyWith(technicianName: initialTechnician1));
      }
    } catch (e) {
      // print(
      //     "🔴 Draft lama untuk $transNo tidak kompatibel. Menghapus draft rusak...");
      _draftBox.delete(transNo);
      final String initialTechnician1 = (_userType == 'WH') ? _userName : '';
      emit(state.copyWith(technicianName: initialTechnician1));
    }
  }

  void _saveDraftToHive(PosUnserviceableState state) {
    EasyDebounce.debounce(
      'save-draft-debouncer-$transNo',
      const Duration(milliseconds: 500),
      () {
        if (state.proofImages.isEmpty &&
            state.selectedReason == null &&
            state.notes.isEmpty &&
            state.technicianName.isEmpty) {
          _draftBox.delete(transNo);
          return;
        }
        final draft = PosUnserviceableModel(
          transNo: transNo,
          reason: state.selectedReason ?? '',
          notes: state.notes,
          proofImages: state.proofImages,
          reportedAt: DateTime.now(),
          reportedBy: '',
          reportedById: '',
          technicianName: state.technicianName,
        );
        _draftBox.put(transNo, draft);
        // print("💾 Draft untuk $transNo berhasil disimpan ke Hive.");
      },
    );
  }

  Future<void> _onTakeProofPhoto(
      TakeProofPhoto event, Emitter<PosUnserviceableState> emit) async {
    if (state.status == UnserviceableStatus.loading) return;
    emit(state.copyWith(status: UnserviceableStatus.loading));

    try {
      // Bersihkan memori gambar sebelum membuka kamera berat
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        emit(state.copyWith(status: UnserviceableStatus.initial));
        return;
      }

      // 1. Siapkan Data User & Waktu
      final userData = await AuthStorage.getUser();
      final technicianName = userData['name'] ?? 'Unknown';
      final deviceModel = userData['device_model'] ?? 'Unknown Device';
      final timestamp = DateTime.now();

      // 2. Siapkan Direktori Permanen
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create();
      }

      // 3. Tentukan Path Tujuan
      final targetPath = p.join(
          imagesDir.path, 'WM_ISSUE_${timestamp.millisecondsSinceEpoch}.jpg');

      // 4. PROSES WATERMARK
      final request = WatermarkRequest(
        originalPath: pickedFile.path,
        targetPath: targetPath,
        transNo: transNo,
        timestamp: timestamp,
        technicianName: technicianName,
        deviceModel: deviceModel,
      );

      final String? finalImagePath = await WatermarkService.processImage(request);

      if (finalImagePath == null) {
        emit(state.copyWith(
            status: UnserviceableStatus.failure,
            errorMessage: 'Gagal memproses watermark foto'));
        return;
      }

      // 5. Ambil GPS (Untuk Metadata)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 6. Simpan ke State
      final imageDetail = CapturedImageDetail(
        imagePath: finalImagePath, // Gunakan path hasil watermark
        timestamp: timestamp,
        latitude: position.latitude,
        longitude: position.longitude,
        address: "",
        technicianName: technicianName,
        deviceModel: deviceModel,
        transNo: transNo,
      );

      final updatedPhotos = List<CapturedImageDetail>.from(state.proofImages)
        ..add(imageDetail);

      emit(state.copyWith(
          proofImages: updatedPhotos, status: UnserviceableStatus.initial));

    } catch (e) {
      emit(state.copyWith(
          status: UnserviceableStatus.failure,
          errorMessage: 'Gagal mengambil foto: $e'));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: UnserviceableStatus.initial));
    }
  }

  void _onRemoveProofPhoto(
      RemoveProofPhoto event, Emitter<PosUnserviceableState> emit) {
    final updatedPhotos = List<CapturedImageDetail>.from(state.proofImages)
      ..remove(event.photoToRemove);
    emit(state.copyWith(proofImages: updatedPhotos));
  }

  void _onReasonSelected(
      ReasonSelected event, Emitter<PosUnserviceableState> emit) {
    emit(state.copyWith(
        selectedReason: event.reason, clearPartialUploadData: true));
  }

  void _onNotesChanged(
      NotesChanged event, Emitter<PosUnserviceableState> emit) {
    emit(state.copyWith(notes: event.notes, clearPartialUploadData: true));
  }

  void _onTechnicianNameChanged(
      TechnicianNameChanged event, Emitter<PosUnserviceableState> emit) {
    emit(state.copyWith(
        technicianName: event.name, clearPartialUploadData: true));
  }

  Future<void> _onSubmitReport(SubmitUnserviceableReport event,
      Emitter<PosUnserviceableState> emit) async {
    if (state.proofImages.isEmpty ||
        state.selectedReason == null ||
        state.technicianName.isEmpty) {
      emit(state.copyWith(
        status: UnserviceableStatus.failure,
        errorMessage: 'Foto bukti, alasan, dan nama teknisi wajib diisi.',
      ));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(status: UnserviceableStatus.initial));
      return;
    }

    emit(state.copyWith(status: UnserviceableStatus.loading));
    try {
      final user = await AuthStorage.getUser();
      final report = PosUnserviceableModel(
        transNo: transNo,
        reason: state.selectedReason!,
        notes: state.notes,
        proofImages: state.proofImages,
        reportedAt: DateTime.now(),
        reportedBy: user['name'] ?? 'Unknown',
        reportedById: user['user_id'] ?? 'Unknown',
        technicianName: state.technicianName,
      );

      final result = await _repository.submitReport(report);

      if (result['status'] == 'OK') {
        emit(state.copyWith(status: UnserviceableStatus.uploading));
        final detailList = result['result']['detail'] as List;

        final List<dynamic> presignedDetails = [];
        for (var item in detailList) {
          if (item['uploads'] is List) {
            presignedDetails.addAll(item['uploads']);
          }
        }

        final uploadResult = await uploadPOSUnserviceableImagesToS3(
          report,
          presignedDetails,
          progressCubit: event.progressCubit,
        );

        if (uploadResult.allSuccess) {
          try {
            final response = await serviceRepo.confirmUploadSuccess(transNo);
            if (response['status'] == 'OK' || response['status'] == 'SUCCESS') {
              await clearTransactionData(transNo);
              emit(state.copyWith(status: UnserviceableStatus.success));
            } else {
              emit(state.copyWith(
                status: UnserviceableStatus.failure,
                errorMessage: "Foto terkirim, tapi gagal update status server: ${response['message']}",
              ));
            }
          } catch (e) {
            emit(state.copyWith(status: UnserviceableStatus.failure, errorMessage: "Gagal konfirmasi status: $e"));
          }
        } else {
          final detailCacheBox =
              await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
          final detailData = detailCacheBox.get(transNo);
          final storeName =
              detailData?.header.shipToName ?? 'Nama Toko Tidak Ditemukan';

          final partialData = {
            'transNo': transNo,
            'presignedDetail': presignedDetails,
            'successCount': uploadResult.successCount,
            'failedFiles': uploadResult.failedFiles,
            'type': 'unserviceable',
            'storeName': storeName,
          };
          final retryBox = await Hive.openBox<Map<dynamic, dynamic>>(
              kPosValidationPartialHiveBox);
          await retryBox.put(transNo, partialData);

          emit(state.copyWith(
            status: UnserviceableStatus.partialFailure,
            partialUploadData: partialData,
          ));
        }
      } else {
        throw Exception(result['message'] ?? 'Gagal mengirim laporan.');
      }
    } catch (e) {
      emit(state.copyWith(
        status: UnserviceableStatus.failure,
        errorMessage: 'Terjadi error: ${e.toString()}',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: UnserviceableStatus.initial));
    }
  }

  Future<void> _onRetryUpload(RetryUnserviceableUpload event,
      Emitter<PosUnserviceableState> emit) async {
    emit(state.copyWith(status: UnserviceableStatus.uploading));

    final report = _draftBox.get(transNo);
    if (report == null) {
      emit(state.copyWith(
          status: UnserviceableStatus.failure,
          errorMessage: 'Data draft tidak ditemukan untuk retry.'));
      return;
    }

    final uploadResult = await uploadPOSUnserviceableImagesToS3(
      report,
      event.presignedDetail,
      progressCubit: event.progressCubit,
      filter: event.failedFiles,
    );

    if (uploadResult.allSuccess) {
      try {
        final response = await serviceRepo.confirmUploadSuccess(transNo);
        if (response['status'] == 'OK' || response['status'] == 'SUCCESS') {
          final retryBox = await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
          await retryBox.delete(transNo);
          await clearTransactionData(transNo);
          emit(state.copyWith(status: UnserviceableStatus.success));
        } else {
          emit(state.copyWith(status: UnserviceableStatus.failure, errorMessage: "Gagal update status server."));
        }
      } catch (e) {
        emit(state.copyWith(status: UnserviceableStatus.failure, errorMessage: "Gagal konfirmasi: $e"));
      }
    } else {
      final partialData = {
        'presignedDetail': event.presignedDetail,
        'failedFiles': uploadResult.failedFiles,
      };
      emit(state.copyWith(
        status: UnserviceableStatus.partialFailure,
        partialUploadData: partialData,
      ));
    }
  }
}

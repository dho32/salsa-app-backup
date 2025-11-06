import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../components/services/hive_clear_service.dart';
import '../../../components/shared_function.dart';
import '../../../components/upload_s3_service.dart';
import '../../../models/proof_of_service/pos_transaction_info_model.dart';
import '../../../models/proof_of_service/pos_unserviceable_model.dart';
import '../../../models/proof_of_service/pos_validation_entry_model.dart';
import '../../../models/proof_of_service/proof_of_service_detail_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';
import 'pos_unserviceable_event.dart';
import 'pos_unserviceable_repository.dart';
import 'pos_unserviceable_state.dart';

class PosUnserviceableBloc
    extends Bloc<PosUnserviceableEvent, PosUnserviceableState> {
  final String transNo;
  final Box<PosUnserviceableModel> _draftBox;
  final PosUnserviceableRepository _repository;

  PosUnserviceableBloc({required this.transNo})
      : _draftBox = Hive.box<PosUnserviceableModel>(kPosUnserviceableDraftsBox),
        _repository = PosUnserviceableRepository(),
        super(const PosUnserviceableState()) {
    on<LoadUnserviceableDraft>(_onLoadInitialData);
    on<TakeProofPhoto>(_onTakeProofPhoto);
    on<RemoveProofPhoto>(_onRemoveProofPhoto);
    on<ReasonSelected>(_onReasonSelected);
    on<NotesChanged>(_onNotesChanged);
    on<SubmitUnserviceableReport>(_onSubmitReport);
    on<RetryUnserviceableUpload>(_onRetryUpload);

    stream
        .where((state) => state.status == UnserviceableStatus.initial)
        .listen((state) {
      _saveDraftToHive(state);
    });

    add(LoadUnserviceableDraft());
  }

  Future<void> _onLoadInitialData(
      LoadUnserviceableDraft event, Emitter<PosUnserviceableState> emit) async {
    final retryBox = await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
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
        ));
      }
    } catch (e) {
      print(
          "🔴 Draft lama untuk $transNo tidak kompatibel. Menghapus draft rusak...");
      _draftBox.delete(transNo);
    }
  }

  void _saveDraftToHive(PosUnserviceableState state) {
    EasyDebounce.debounce(
      'save-draft-debouncer-$transNo',
      const Duration(milliseconds: 500),
      () {
        if (state.proofImages.isEmpty &&
            state.selectedReason == null &&
            state.notes.isEmpty) {
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
        );
        _draftBox.put(transNo, draft);
        print("💾 Draft untuk $transNo berhasil disimpan ke Hive.");
      },
    );
  }

  Future<void> _onTakeProofPhoto(
      TakeProofPhoto event, Emitter<PosUnserviceableState> emit) async {
    if (state.status == UnserviceableStatus.loading) return;
    emit(state.copyWith(status: UnserviceableStatus.loading));

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile == null) {
        emit(state.copyWith(status: UnserviceableStatus.initial));
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      final XFile? compressedImage =
          await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1920,
      );

      if (compressedImage == null) {
        emit(state.copyWith(status: UnserviceableStatus.initial));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final user = await AuthStorage.getUser();

      final imageDetail = CapturedImageDetail(
        imagePath: compressedImage.path,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        address: "",
        technicianName: user['name'] ?? 'Unknown',
        deviceModel: user['device_model'] ?? "Device Model Placeholder",
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

  Future<void> _onSubmitReport(SubmitUnserviceableReport event,
      Emitter<PosUnserviceableState> emit) async {
    if (state.proofImages.isEmpty || state.selectedReason == null) {
      emit(state.copyWith(
        status: UnserviceableStatus.failure,
        errorMessage: 'Foto bukti dan alasan wajib diisi.',
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
          await _clearAllTransactionData();
          emit(state.copyWith(status: UnserviceableStatus.success));
        } else {

          final detailCacheBox = await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
          final detailData = detailCacheBox.get(transNo);
          final storeName = detailData?.header.shipToName ?? 'Nama Toko Tidak Ditemukan';

          final partialData = {
            'transNo': transNo,
            'presignedDetail': presignedDetails,
            'successCount': uploadResult.successCount,
            'failedFiles': uploadResult.failedFiles,
            'type': 'unserviceable',
            'storeName': storeName,
          };
          final retryBox = await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
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
      final retryBox = await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
      await retryBox.delete(transNo);
      await _clearAllTransactionData();
      emit(state.copyWith(status: UnserviceableStatus.success));
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

  // Method baru untuk membersihkan semua data terkait transaksi ini
  Future<void> _clearAllTransactionData() async {
    // // 1. Hapus draft laporan unserviceable
    // await _draftBox.delete(transNo);
    //
    // // 2. Hapus cache detail utama dari halaman sebelumnya
    // final detailCacheBox =
    //     await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
    // await detailCacheBox.delete(transNo);
    //
    // // 3. Hapus info transaksi (PIC, teknisi, dll)
    // final infoBox =
    //     await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    // await infoBox.delete(getHiveKeyForTransaction(transNo));
    //
    // // 4. Hapus data validasi unit (jika teknisi sempat mengisinya)
    // final validationBox =
    //     await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
    // final validationKeysToDelete = validationBox.keys.where((key) {
    //   final entry = validationBox.get(key);
    //   return entry != null && entry.transNo == transNo;
    // }).toList();
    // await validationBox.deleteAll(validationKeysToDelete);


    await clearTransactionData(transNo);
    final queueBox =
    await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
    final task =
    ConfirmationTaskModel(transNo: transNo.trim().toUpperCase());
    await queueBox.put(transNo.trim().toUpperCase(), task);

    print("🧹 Semua data Hive untuk transaksi $transNo telah dibersihkan.");
  }
}

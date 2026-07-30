import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../components/constants.dart';
import '../../../components/upload_s3_service.dart';
import '../../../models/rro_cut_off/rro_cut_off_entry_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';
import '../../service/service_repository.dart';
import 'rro_cut_off_submit_event.dart';
import 'rro_cut_off_submit_state.dart';
import 'rro_cut_off_submit_repository.dart';

class RROCutOffSubmitBloc
    extends Bloc<RROCutOffSubmitEvent, RROCutOffSubmitState> {
  final RROCutOffSubmitRepository repository;
  final ServiceTaskRepository serviceRepo;

  RROCutOffSubmitBloc({required this.repository})
      : serviceRepo = ServiceTaskRepository(),
        super(const RROCutOffSubmitState()) {
    on<SubmitRroData>(_onSubmitData);
  }

  Future<void> _onSubmitData(
      SubmitRroData event, Emitter<RROCutOffSubmitState> emit) async {
    emit(state.copyWith(status: RROCutOffSubmitStatus.loading));

    try {
      // 1. TEMBAK API METADATA JSON
      final apiResult = await repository.submitPayloadRRO(event.payload);

      if (apiResult['status'] != 'OK') throw apiResult['message'];

      // 2. TRIGGER UPLOAD S3 & PROGRESS BAR (Lewat Repository Global)
      emit(state.copyWith(status: RROCutOffSubmitStatus.uploading));

      final uploadResult = await uploadRROCutOffFiles(
        apiResult: apiResult,
        progressCubit: event.progressCubit,
        transNo: event.transNo,
      );

      // 3. PENANGANAN HASIL UPLOAD
      if (uploadResult.allSuccess) {
        // SUKSES SEMUA
        try {
          // confirmUploadSuccess TIDAK pernah throw — ia mengembalikan
          // {'status':'ERROR'} bila gagal, jadi statusnya WAJIB dicek manual.
          final confirmResponse =
              await serviceRepo.confirmUploadSuccess(event.transNo);

          // Foto sudah aman di S3 & metadata sudah tersimpan di server; yang
          // gagal hanya update status task. Antrikan ke ConfirmationService
          // agar di-retry otomatis saat startup (maks 5x), pola sama dengan
          // modul lain (mis. SC unserviceable). Tanpa ini konfirmasi hilang
          // diam-diam padahal draft sudah kadung dihapus.
          if (confirmResponse['status'] != 'OK') {
            final queueBox = Hive.isBoxOpen(kConfirmationQueueBox)
                ? Hive.box<ConfirmationTaskModel>(kConfirmationQueueBox)
                : await Hive.openBox<ConfirmationTaskModel>(
                    kConfirmationQueueBox);
            await queueBox.put(
                event.transNo, ConfirmationTaskModel(transNo: event.transNo));
          }

          final draftBox = await Hive.openBox(kRROFormDraftBox);
          await draftBox.deleteAll([
            '${event.transNo}_picName',
            '${event.transNo}_picPhone',
            '${event.transNo}_picNik',
            '${event.transNo}_picPosition',
            '${event.transNo}_tech1',
            '${event.transNo}_tech2',
            '${event.transNo}_tech3',
            '${event.transNo}_tech1Nik',
            '${event.transNo}_tech2Nik',
            '${event.transNo}_tech3Nik',
            '${event.transNo}_storeFrontPhoto',
            '${event.transNo}_storeFrontLat',
            '${event.transNo}_storeFrontLng',
            '${event.transNo}_isPicActive',
            '${event.transNo}_picPhotoPath',
            '${event.transNo}_picLat',
            '${event.transNo}_picLng',
          ]);

          final entryBox =
              await Hive.openBox<RROCutOffEntryModel>(kRROCutOffEntryBox);
          final keysToDelete = entryBox.keys
              .where((k) => entryBox.get(k)?.transNo == event.transNo)
              .toList();
          await entryBox.deleteAll(keysToDelete);

          // Bersihkan juga entry pembawa foto PIC (RROCutOffFormModel) di box
          // form supaya tidak menumpuk pointer foto basi lintas transaksi.
          final formBox =
              await Hive.openBox<RROCutOffFormModel>(kRROCutOffFormBox);
          final formKeys = formBox.keys
              .where((k) => formBox.get(k)?.transNo == event.transNo)
              .toList();
          await formBox.deleteAll(formKeys);

          emit(state.copyWith(status: RROCutOffSubmitStatus.success));
        } catch (e) {
          emit(state.copyWith(
            status: RROCutOffSubmitStatus.uploadPartial,
            successCount: uploadResult.successCount,
            failureCount: 1,
            failedFiles: ["Gagal finalisasi (konfirmasi / bersih draft): $e"],
          ));
        }
      } else {
        // PARTIAL UPLOAD
        Box<Map<dynamic, dynamic>> failedBox;
        if (Hive.isBoxOpen(kFailedUploadsBox)) {
          failedBox = Hive.box<Map<dynamic, dynamic>>(kFailedUploadsBox);
        } else {
          failedBox =
              await Hive.openBox<Map<dynamic, dynamic>>(kFailedUploadsBox);
        }

        await failedBox.put(event.transNo, {
          'transNo': event.transNo,
          'module': 'RRO_CUT_OFF',
          'timestamp': DateTime.now().toIso8601String(),
          'failedFiles': uploadResult.failedFiles,
          'presignedDetail': apiResult['result']['detail'],
          'storeName': event.storeName,
        });

        emit(state.copyWith(
          status: RROCutOffSubmitStatus.uploadPartial,
          successCount: uploadResult.successCount,
          failureCount: uploadResult.failureCount,
          failedFiles: uploadResult.failedFiles,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
          status: RROCutOffSubmitStatus.failure,
          errorMessage: e.toString().replaceAll("Exception: ", "")));
    }
  }
}

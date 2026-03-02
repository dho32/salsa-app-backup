import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_repository.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/upload_s3_service.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model_ext.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model_ext.dart';

import '../../../components/services/hive_clear_service.dart';
import '../../../models/proof_of_service/proof_of_service_detail_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';
import '../../../screens/common/services/confirmation_service.dart';
import '../../service/service_repository.dart';

class PosSubmittedBloc extends Bloc<PosSubmittedEvent, PosSubmittedState> {
  final PosSubmittedRepository repository;
  final serviceRepo = ServiceTaskRepository();

  PosSubmittedBloc({required this.repository}) : super(PosValidationInitial()) {
    on<SubmitPosValidation>(_onSubmitValidation);
    on<RetryPosUpload>(_onRetryUpload);
    on<LoadPosValidationPartial>(_onLoadValidationPartial);
    on<FinalValidationRequested>(_onFinalValidationRequested);
  }

  Future<void> _onFinalValidationRequested(
      FinalValidationRequested event,
      Emitter<PosSubmittedState> emit,
      ) async {
    emit(PosValidationSubmitting()); // Tampilkan loading spinner kecil
    try {
      final validationBox = await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      final entries = validationBox.values.where((e) => e.transNo == event.transNo).toList();

      final bool hasBrokenUnit = entries.any((entry) {

        // Jika isGeneric == true, langsung return false
        if (entry.isGeneric == true) {
          return false;
        }

        // Kondisi 1: Cek catatan
        final bool isNoteBroken = entry.note?.trim().toLowerCase().contains('ac rusak / bermasalah') ?? false;

        // Kondisi 2: Cek apakah ada pengukuran yang di-skip
        final bool isMeasurementSkipped = entry.measurementsAfter.any((m) => m.isSkipped ?? false);

        // Hasil akhir: Keduanya harus true
        return isNoteBroken && isMeasurementSkipped;
      });
      print(hasBrokenUnit);

      if (hasBrokenUnit) {
        final bool hasActiveSC = await repository.checkActiveServiceCall(event.transNo);
        print(hasActiveSC);
        if (!hasActiveSC) {
          emit(ShowCreateServiceCallDialog());
          return;
        }
      }

      // Jika semua pengecekan lolos, beri perintah untuk lanjut ke OTP
      emit(ProceedToOtpDialog(event.formState));

    } catch (e) {
      emit(PosValidationFailure("Gagal melakukan validasi akhir: ${e.toString()}"));
    }
  }

  Future<void> _onSubmitValidation(
      SubmitPosValidation event,
      Emitter<PosSubmittedState> emit,
      ) async {
    print("masuk validate");
    emit(PosValidationSubmitting());
    try {
      // 1. Ambil data validasi unit dari Hive
      final validationBox = await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);

      // Filter sesuai Trans No
      final entries = validationBox.values
          .where((e) => e.transNo.trim().toUpperCase() == event.transNo.trim().toUpperCase())
          .toList();

      if (entries.isEmpty) {
        emit(PosValidationFailure("Data validasi unit tidak ditemukan."));
        return;
      }

      // --- LOGIC PAIRING (Pemetaan Indoor <-> Outdoor) ---
      final pairingMap = <String, String>{};
      for (final entry in entries) {
        // Jika Outdoor punya pasangan, catat: [SN_Indoor] = SN_Outdoor
        if (entry.articleType?.toUpperCase() == 'OUT' && entry.pairedSerialNo != null) {
          pairingMap[entry.pairedSerialNo!] = entry.serialNo;
        }
      }

      // --- 🔥 MAPPING MANUAL PAYLOAD (Biar Format Konsisten) 🔥 ---
      final itemsPayload = entries.map((entry) {
        // Tentukan pasangan jika ini unit Indoor
        String? pairedSerial;
        if (entry.articleType?.toUpperCase() == 'IN') {
          pairedSerial = pairingMap[entry.serialNo];
        } else {
          pairedSerial = entry.pairedSerialNo;
        }

        return {
          "serial_no": entry.serialNo,
          "article_no": entry.articleNo ?? "",
          "article_desc": entry.articleDesc ?? "",
          "article_unit_desc": entry.articleUnitDesc ?? "",

          "article_type": entry.articleType,
          "note": entry.note ?? "",
          "remark": entry.noteRemark,
          "remark_photos": (entry.remarkPhotos ?? []).map((e) => e.toJson()).toList(),

          "images_before": entry.photosBefore.map((p) => {
            "image_file_name": p.imagePath.split('/').last,
            "timestamp": DateFormat("yyyy-MM-dd HH:mm:ss").format(p.timestamp),
            "latitude": p.latitude ?? 0.0,
            "longitude": p.longitude ?? 0.0,
            "device": p.deviceModel
          }).toList(),

          "images_after": entry.photosAfter.map((p) => {
            "image_file_name": p.imagePath.split('/').last,
            "timestamp": DateFormat("yyyy-MM-dd HH:mm:ss").format(p.timestamp),
            "latitude": p.latitude ?? 0.0,
            "longitude": p.longitude ?? 0.0,
            "device": p.deviceModel
          }).toList(),

          "measurements_after": entry.measurementsAfter.map((m) => {
            "measurement_id": m.measurementId,
            "value": m.value,
            "unit": m.unit,
            "is_skipped": m.isSkipped ?? false,
            if (m.capturedImage != null)
              "image": {
                "image_file_name": m.capturedImage?.imagePath.split('/').last,
                // Ambil timestamp foto, atau fallback ke jam sekarang (tanpa milidetik)
                //DateFormat("yyyy-MM-dd HH:mm:ss").format(timestamp)
                "timestamp": DateFormat("yyyy-MM-dd HH:mm:ss").format(m.capturedImage!.timestamp) ,
                "latitude": 0.0,
                "longitude": 0.0,
                "device": m.capturedImage?.deviceModel
              }
          }).toList(),
          "exclude_qty": entry.excludeQty ?? false,
          "paired_serial_no": pairedSerial,
          "reff_line_no": entry.reffLineNo
        };
      }).toList();

      // 2. Ambil data PIC & Teknisi dari Hive
      final infoBox = await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
      final transactionInfo = infoBox.get(getHiveKeyForTransaction(event.transNo.trim().toUpperCase()));

      // 3. Panggil repository untuk mengirim data
      final result = await repository.submitPosValidation(
        transNo: event.transNo.trim().toUpperCase(),
        createdBy: event.createdBy,
        createdByName: event.createdByName,
        createdByIp: event.createdByIP,
        transactionInfo: transactionInfo,
        items: itemsPayload,
      );

      if (result['status'] == 'OK') {
        emit(PosValidationUploadInProgress());
        final presignedDetail = result['result']['detail'];

        // 4. Panggil service untuk upload foto ke S3
        final uploadResult = await uploadPosImagesToS3(
            event.transNo.trim().toUpperCase(), presignedDetail,
            progressCubit: event.progressCubit);

        if (uploadResult.allSuccess) {
          try {
            final response = await serviceRepo.confirmUploadSuccess(event.transNo);

            if (response['status'] == 'OK') {
              await clearTransactionData(event.transNo);
              emit(PosValidationSuccess());
            } else {
              emit(PosValidationFailure("Foto terunggah, tapi gagal update status server: ${response['message']}"));
            }
          } catch (e) {
            emit(PosValidationFailure("Gagal konfirmasi status ke server: $e"));
          }
        } else {
          // --- LOGIC PARTIAL FAILURE (CACHE) ---
          final cleanFailedFiles = uploadResult.failedFiles.map((fullErrorString) {
            return fullErrorString.split(' (').first;
          }).toList();

          final detailCacheBox = await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
          final detailData = detailCacheBox.get(event.transNo);
          final storeName = detailData?.header.shipToName ?? 'Nama Toko Tidak Ditemukan';

          final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
          await cacheBox.put(event.transNo, {
            'transNo': event.transNo,
            'failedFiles': cleanFailedFiles,
            'presignedDetail': presignedDetail,
            'storeName': storeName,
            'module': 'POS',
          });

          emit(PosValidationUploadPartial(
            successCount: uploadResult.successCount,
            failureCount: uploadResult.failureCount,
            failedFiles: cleanFailedFiles,
            transNo: event.transNo,
            presignedDetail: presignedDetail,
          ));
        }
      } else {
        emit(PosValidationFailure(result['message'] ?? 'Gagal mengirim data validasi.'));
      }
    } catch (e) {
      print("ERROR SUBMIT POS: $e"); // Print error biar kebaca di debug console
      emit(PosValidationFailure("Terjadi error: ${e.toString()}"));
    }
  }

  Future<void> _onRetryUpload(
    RetryPosUpload event,
    Emitter<PosSubmittedState> emit,
  ) async {
    emit(PosValidationSubmitting());
    try {
      final result = await uploadPosImagesToS3(
        event.transNo,
        event.presignedDetail,
        filter: event.failedFiles, // Hanya upload ulang file yang gagal
        progressCubit: event.progressCubit,
      );

      // final validationBox =
      //     await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      // final infoBox = await Hive.openBox<PosTransactionInfoModel>(
      //     kPosTransactionInfoHiveBox);

      if (result.allSuccess) {
        try {
          final response = await serviceRepo.confirmUploadSuccess(event.transNo);

          if (response['status'] == 'OK') {
            await clearTransactionData(event.transNo);
            emit(PosValidationSuccess());
          } else {
            emit(PosValidationFailure("Gagal update status server: ${response['message']}"));
          }
        } catch (e) {
          emit(PosValidationFailure("Gagal konfirmasi ke server: $e"));
        }
      } else {
        // Jika masih gagal, update cache dengan sisa file yang masih gagal
        final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
        final cleanFailedFiles = result.failedFiles.map((e) => e.split(' (').first).toList();

        await cacheBox.put(event.transNo, {
          'transNo': event.transNo,
          'failedFiles': cleanFailedFiles,
          'presignedDetail': event.presignedDetail,
        });
        emit(PosValidationUploadPartial(
          successCount: result.successCount,
          failureCount: result.failureCount,
          failedFiles: cleanFailedFiles,
          transNo: event.transNo,
          presignedDetail: event.presignedDetail,
        ));
      }
    } catch (e) {
      emit(PosValidationFailure(
          "Terjadi error saat mencoba ulang: ${e.toString()}"));
    }
  }

  Future<void> _onLoadValidationPartial(
    LoadPosValidationPartial event,
    Emitter<PosSubmittedState> emit,
  ) async {
    final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
    final cached = cacheBox.get(event.transNo);

    if (cached != null) {
      emit(PosValidationUploadPartial(
        successCount: 0,
        // Nilai awal saat load
        failureCount: (cached['failedFiles'] as List).length,
        failedFiles: List<String>.from(cached['failedFiles']),
        transNo: event.transNo,
        presignedDetail: List<dynamic>.from(cached['presignedDetail']),
      ));
    }
  }

  // Helper untuk normalisasi kunci, pastikan sama dengan yang di UI
  String getHiveKeyForTransaction(String transNo) {
    return transNo.toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }
}

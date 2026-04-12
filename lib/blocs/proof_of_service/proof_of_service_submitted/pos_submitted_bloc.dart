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
    emit(PosValidationSubmitting());
    try {
      final validationBox =
          await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      final entries = validationBox.values
          .where((e) => e.transNo == event.transNo)
          .toList();

      final bool hasBrokenUnit = entries.any((entry) {
        if (entry.isGeneric == true) return false;
        final bool isNoteBroken = entry.note
                ?.trim()
                .toLowerCase()
                .contains('ac rusak / bermasalah') ??
            false;
        final bool isMeasurementSkipped =
            entry.measurementsAfter.any((m) => m.isSkipped ?? false);
        return isNoteBroken && isMeasurementSkipped;
      });

      if (hasBrokenUnit) {
        final bool hasActiveSC =
            await repository.checkActiveServiceCall(event.transNo);
        if (!hasActiveSC) {
          emit(ShowCreateServiceCallDialog());
          return;
        }
      }
      emit(ProceedToOtpDialog(event.formState));
    } catch (e) {
      emit(PosValidationFailure(
          "Gagal melakukan validasi akhir: ${e.toString()}"));
    }
  }

  Future<void> _onSubmitValidation(
    SubmitPosValidation event,
    Emitter<PosSubmittedState> emit,
  ) async {
    print("masuk validate");
    emit(PosValidationSubmitting());
    try {
      final validationBox =
          await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      final entries = validationBox.values
          .where((e) =>
              e.transNo.trim().toUpperCase() ==
              event.transNo.trim().toUpperCase())
          .toList();

      if (entries.isEmpty) {
        emit(PosValidationFailure("Data validasi unit tidak ditemukan."));
        return;
      }

      // 🔥 --- SUNTIKAN 1: SATPAM ANTI-ZOMBIE (CEK UMUR FOTO) --- 🔥
      for (final entry in entries) {
        final allPhotos = [
          ...entry.photosBefore,
          ...entry.photosAfter,
          ...(entry.remarkPhotos ?? [])
        ];

        // Cek juga foto di measurement
        for (final m in entry.measurementsAfter) {
          if (m.capturedImage != null) allPhotos.add(m.capturedImage!);
        }

        // Sapu bersih foto basi
        for (final photo in allPhotos) {
          // Jika umur foto > 3 hari (72 jam), ini PASTI foto nyangkut bulan lalu!
          if (DateTime.now().difference(photo.timestamp).inHours > 72) {
            emit(PosValidationFailure(
                "🚨 DITEMUKAN DATA USANG PADA UNIT ${entry.serialNo}!\n\n"
                "Sistem mendeteksi foto yang diambil beberapa hari/bulan yang lalu.\n"
                "Mohon HAPUS DRAFT unit ini, foto ulang, dan isi kembali."));
            return; // BLOKIR PENGIRIMAN KE SERVER!
          }
        }
      }
      // 🔥 ---------------------------------------------------- 🔥

      final pairingMap = <String, String>{};
      for (final entry in entries) {
        if (entry.articleType?.toUpperCase() == 'OUT' &&
            entry.pairedSerialNo != null) {
          pairingMap[entry.pairedSerialNo!] = entry.serialNo;
        }
      }

      final itemsPayload = entries.map((entry) {
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
          "remark_photos":
              (entry.remarkPhotos ?? []).map((e) => e.toJson()).toList(),
          "images_before": entry.photosBefore
              .map((p) => {
                    "image_file_name": p.imagePath.split('/').last,
                    "timestamp":
                        DateFormat("yyyy-MM-dd HH:mm:ss").format(p.timestamp),
                    "latitude": p.latitude ?? 0.0,
                    "longitude": p.longitude ?? 0.0,
                    "device": p.deviceModel
                  })
              .toList(),
          "images_after": entry.photosAfter
              .map((p) => {
                    "image_file_name": p.imagePath.split('/').last,
                    "timestamp":
                        DateFormat("yyyy-MM-dd HH:mm:ss").format(p.timestamp),
                    "latitude": p.latitude ?? 0.0,
                    "longitude": p.longitude ?? 0.0,
                    "device": p.deviceModel
                  })
              .toList(),
          "measurements_after": entry.measurementsAfter
              .map((m) => {
                    "measurement_id": m.measurementId,
                    "value": m.value,
                    "unit": m.unit,
                    "is_skipped": m.isSkipped ?? false,
                    if (m.capturedImage != null)
                      "image": {
                        "image_file_name":
                            m.capturedImage?.imagePath.split('/').last,
                        "timestamp": DateFormat("yyyy-MM-dd HH:mm:ss")
                            .format(m.capturedImage!.timestamp),
                        "latitude": 0.0,
                        "longitude": 0.0,
                        "device": m.capturedImage?.deviceModel
                      }
                  })
              .toList(),
          "exclude_qty": entry.excludeQty ?? false,
          "paired_serial_no": pairedSerial,
          "reff_line_no": entry.reffLineNo
        };
      }).toList();

      final infoBox = await Hive.openBox<PosTransactionInfoModel>(
          kPosTransactionInfoHiveBox);
      final transactionInfo = infoBox
          .get(getHiveKeyForTransaction(event.transNo.trim().toUpperCase()));

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

        final uploadResult = await uploadPosImagesToS3(
            event.transNo.trim().toUpperCase(), presignedDetail,
            progressCubit: event.progressCubit);

        if (uploadResult.allSuccess) {
          try {
            final response =
                await serviceRepo.confirmUploadSuccess(event.transNo);

            if (response['status'] == 'OK') {
              await clearTransactionData(event.transNo);

              // 🔥 --- SUNTIKAN 2: SAPU BERSIH ZOMBIE MANUAL --- 🔥
              // Ini failsafe kalau clearTransactionData() gagal ngehapus data di Hive
              final keysToDelete = validationBox.keys.where((k) {
                final e = validationBox.get(k);
                return e?.transNo == event.transNo;
              }).toList();
              if (keysToDelete.isNotEmpty) {
                await validationBox.deleteAll(keysToDelete);
              }
              // 🔥 ----------------------------------------------- 🔥

              emit(PosValidationSuccess());
            } else {
              emit(PosValidationFailure(
                  "Foto terunggah, tapi gagal update status server: ${response['message']}"));
            }
          } catch (e) {
            emit(PosValidationFailure("Gagal konfirmasi status ke server: $e"));
          }
        } else {
          final cleanFailedFiles =
              uploadResult.failedFiles.map((fullErrorString) {
            return fullErrorString.split(' (').first;
          }).toList();

          final detailCacheBox =
              await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
          final detailData = detailCacheBox.get(event.transNo);
          final storeName =
              detailData?.header.shipToName ?? 'Nama Toko Tidak Ditemukan';

          final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(
              kPosValidationPartialHiveBox);
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
        emit(PosValidationFailure(
            result['message'] ?? 'Gagal mengirim data validasi.'));
      }
    } catch (e) {
      print("ERROR SUBMIT POS: $e");
      emit(PosValidationFailure("Terjadi error: ${e.toString()}"));
    }
  }

  Future<void> _onRetryUpload(
      RetryPosUpload event, Emitter<PosSubmittedState> emit) async {
    // ... (Kode _onRetryUpload Akang tetap sama, saya skip tulis ulang biar gak kepanjangan,
    // TAPI pastikan tambahkan kode SUNTIKAN 2 di blok IF success-nya juga!)
    emit(PosValidationSubmitting());
    try {
      final result = await uploadPosImagesToS3(
        event.transNo,
        event.presignedDetail,
        filter: event.failedFiles,
        progressCubit: event.progressCubit,
      );

      if (result.allSuccess) {
        try {
          final response =
              await serviceRepo.confirmUploadSuccess(event.transNo);

          if (response['status'] == 'OK') {
            await clearTransactionData(event.transNo);

            // 🔥 SAPU BERSIH MANUAL SAAT RETRY SUKSES 🔥
            final validationBox = await Hive.openBox<PosValidationEntryModel>(
                kPosValidationHiveBox);
            final keysToDelete = validationBox.keys.where((k) {
              final e = validationBox.get(k);
              return e?.transNo == event.transNo;
            }).toList();
            await validationBox.deleteAll(keysToDelete);
            // 🔥 ------------------------------------- 🔥

            emit(PosValidationSuccess());
          } else {
            emit(PosValidationFailure(
                "Gagal update status server: ${response['message']}"));
          }
        } catch (e) {
          emit(PosValidationFailure("Gagal konfirmasi ke server: $e"));
        }
      } else {
        final cacheBox = await Hive.openBox<Map<dynamic, dynamic>>(
            kPosValidationPartialHiveBox);
        final cleanFailedFiles =
            result.failedFiles.map((e) => e.split(' (').first).toList();

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
    final cacheBox =
        await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
    final cached = cacheBox.get(event.transNo);

    if (cached != null) {
      emit(PosValidationUploadPartial(
        successCount: 0,
        failureCount: (cached['failedFiles'] as List).length,
        failedFiles: List<String>.from(cached['failedFiles']),
        transNo: event.transNo,
        presignedDetail: List<dynamic>.from(cached['presignedDetail']),
      ));
    }
  }

  String getHiveKeyForTransaction(String transNo) {
    return transNo.toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }
}

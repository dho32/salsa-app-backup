import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_repository.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/upload_s3_service.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/models/proof_of_service/pos_validasion_entry_model_ext.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';

import '../../../components/services/hive_clear_service.dart';
import '../../../models/proof_of_service/proof_of_service_detail_model.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';

class PosSubmittedBloc extends Bloc<PosSubmittedEvent, PosSubmittedState> {
  final PosSubmittedRepository repository;

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

      print("test");
      final bool hasBrokenUnit = entries.any((entry) {
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
        if (!hasActiveSC) {
          emit(ShowCreateServiceCallDialog());
          return;
        }
      }

      // Jika semua pengecekan lolos, beri perintah untuk lanjut ke OTP
      emit(ProceedToOtpDialog());

    } catch (e) {
      emit(PosValidationFailure("Gagal melakukan validasi akhir: ${e.toString()}"));
    }
  }

  Future<void> _onSubmitValidation(
    SubmitPosValidation event,
    Emitter<PosSubmittedState> emit,
  ) async {
    emit(PosValidationSubmitting());
    try {
      // 1. Ambil data validasi unit dari Hive
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

      final pairingMap = <String, String>{};
      for (final entry in entries) {
        if (entry.articleType?.toUpperCase() == 'OUT' && entry.pairedSerialNo != null) {
          pairingMap[entry.pairedSerialNo!] = entry.serialNo;
        }
      }

      final itemsPayload = entries.map((entry) {
        // Ambil data JSON dasar dari model
        final json = entry.toJson();

        // Jika unit ini adalah INDOOR...
        if (entry.articleType?.toUpperCase() == 'IN') {
          // ...cek di peta apakah ada outdoor yang memilihnya.
          final outdoorPairSerialNo = pairingMap[entry.serialNo];
          if (outdoorPairSerialNo != null) {
            // Jika ada, isi field 'paired_serial_no' dengan SN outdoor pasangannya.
            // Nama field di API kita asumsikan tetap sama untuk indoor dan outdoor.
            json['paired_serial_no'] = outdoorPairSerialNo;
          }
        }
        return json;
      }).toList();

      // 2. Ambil data PIC & Teknisi dari Hive
      final infoBox = await Hive.openBox<PosTransactionInfoModel>(
          kPosTransactionInfoHiveBox);
      final transactionInfo = infoBox
          .get(getHiveKeyForTransaction(event.transNo.trim().toUpperCase()));

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
          // 5. Jika semua sukses, hapus data dari Hive
          // for (var entry in entries) {
          //   await validationBox.delete(entry.serialNo.trim().toUpperCase());
          // }
          // await infoBox.delete(
          //     getHiveKeyForTransaction(event.transNo.trim().toUpperCase()));

          await clearTransactionData(event.transNo);
          final queueBox =
              await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
          final task = ConfirmationTaskModel(
              transNo: event.transNo.trim().toUpperCase());
          await queueBox.put(event.transNo.trim().toUpperCase(), task);

          emit(PosValidationSuccess());
        } else {
          final cleanFailedFiles = uploadResult.failedFiles.map((fullErrorString) {
            return fullErrorString.split(' (').first;
          }).toList();

          final detailCacheBox = await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
          final detailData = detailCacheBox.get(event.transNo);
          final storeName = detailData?.header.shipToName ?? 'Nama Toko Tidak Ditemukan';

          final cacheBox = await Hive.openBox(kPosValidationPartialHiveBox);
          await cacheBox.put(event.transNo, {
            'transNo': event.transNo,
            'failedFiles': cleanFailedFiles,
            'presignedDetail': presignedDetail,
            'storeName': storeName,
          });

          // Pancarkan state gagal sebagian
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
        // Jika retry berhasil, hapus semua data
        // final toDelete =
        //     validationBox.values.where((e) => e.transNo == event.transNo);
        // for (var entry in toDelete) {
        //   await validationBox.delete(entry.serialNo.trim().toUpperCase());
        // }
        // await infoBox.delete(getHiveKeyForTransaction(event.transNo));
        // await cacheBox.delete(event.transNo);

        await clearTransactionData(event.transNo);
        final queueBox =
            await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
        final task =
            ConfirmationTaskModel(transNo: event.transNo.trim().toUpperCase());
        await queueBox.put(event.transNo.trim().toUpperCase(), task);

        emit(PosValidationSuccess());
      } else {
        // Jika masih gagal, update cache dengan sisa file yang masih gagal
        final cacheBox = await Hive.openBox(kPosValidationPartialHiveBox);
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
    final cacheBox = await Hive.openBox(kPosValidationPartialHiveBox);
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
    return transNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }
}

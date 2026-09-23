import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../components/upload_s3_service.dart';
import '../../../models/common/captured_image_detail.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_entry_model.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';
// Ekstensi CapturedImageDetail.toJson() (nama file + timestamp + lat/long +
// device) — backend cuci freezer memakai bentuk foto yang SAMA dengan SC/SCF.
import '../../../models/service_call/service_call_validation_entry_model_ext.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';
import '../../service/service_repository.dart';
import '../../upload_progress/upload_progress_cubit.dart';
import 'posf_submitted_repository.dart';

part 'posf_submitted_event.dart';
part 'posf_submitted_state.dart';

class PosfSubmittedBloc extends Bloc<PosfSubmittedEvent, PosfSubmittedState> {
  final PosfSubmittedRepository repository;

  PosfSubmittedBloc({required this.repository}) : super(PosfSubmittedInitial()) {
    on<SubmitPosfValidation>(_onSubmit);
  }

  String _key(String t) =>
      t.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  bool _isDemoTransNo(String t) =>
      t.trim().toUpperCase() == kDummyPosfTransNo.trim().toUpperCase();

  Future<void> _onSubmit(
      SubmitPosfValidation event, Emitter<PosfSubmittedState> emit) async {
    emit(PosfSubmitting());
    try {
      final entryBox =
          await Hive.openBox<ProofOfServiceFreezerEntryModel>(kProofOfServiceFreezerEntryBox);
      final infoBox =
          await Hive.openBox<ProofOfServiceFreezerInfoModel>(kProofOfServiceFreezerInfoBox);

      final tx = event.transNo.trim().toUpperCase();
      final entries =
          entryBox.values.where((e) => e.transNo.trim().toUpperCase() == tx).toList();
      if (entries.isEmpty) {
        emit(const PosfSubmitFailure('Belum ada freezer yang divalidasi.'));
        return;
      }

      // DEMO: task dummy tidak dikirim ke backend. Lewati submit API + upload
      // S3 + konfirmasi; cukup tampilkan sukses lalu bersihkan draft (entry +
      // info/PIC) agar langsung bisa dicoba input ulang.
      if (kEnableDummyDemoTasks && _isDemoTransNo(event.transNo)) {
        // Tampilkan dialog progres upload sesaat DULU lalu sukses. Handler state
        // sukses menutup dialog teratas (if canPop → pop); di demo tak ada
        // langkah upload nyata, jadi tanpa dialog progres ini pop malah menutup
        // LAYAR DETAIL dan dialog sukses muncul di context yang sudah di-pop →
        // tombol OK tak berfungsi. Emit progres dulu agar yang di-pop dialog itu.
        emit(PosfUploadInProgress());
        await _clearDrafts(event.transNo, entryBox, infoBox);
        emit(PosfSubmitSuccess());
        return;
      }

      final info = infoBox.get(_key(event.transNo));

      // Data hulu per unit (unit_desc & line_no) hanya ada di detail box dari
      // server, bukan di draft. Backend memakainya sebagai article_unit_desc &
      // reff_line_no — penghubung baris cuci freezer ke baris PO aslinya.
      // Unit dicocokkan lewat unit_index (serial kosong pada unit generic).
      final serverUnits = await _serverUnits(event.transNo);

      // Urutan item = LineSeq di backend (detail.line_no = LineSeq * 10), jadi
      // kirim berurut unit_index, bukan urutan insert Hive.
      entries.sort((a, b) => a.unitIndex.compareTo(b.unitIndex));

      final items = entries.map((e) {
        final unit = serverUnits[e.unitIndex];
        return {
          'serial_no': e.serialNo,
          'article_no': e.articleNo,
          'article_desc': e.articleDesc,
          'unit_desc': unit?.unitDesc ?? '',
          'line_no': unit?.lineNo ?? 0,
          // Kondisi draft = string gabungan 2 dimensi (mis. "Ada Keluhan Tidak
          // Terpakai"); backend memintanya terpisah.
          'general_condition': posfGeneralCondition(e.generalCondition),
          'usage_condition': posfUsageCondition(e.generalCondition),
          'complaint': e.complaint,
          // Alasan dimensi "Tidak Terpakai" (terpisah dari keluhan).
          'unused_reason': e.unusedReason,
          // Detail kondisi "Ada Keluhan"/"Tidak terpakai": keterangan
          // tambahan + foto bukti.
          'condition_note': e.conditionNote ?? '',
          'condition_photos':
              (e.conditionPhotos ?? []).map((p) => p.toJson()).toList(),
          // Tanpa keterangan ukuran: backend hanya menerima Tipis/Sedang/Tebal.
          'frost_thickness': posfFrostThicknessValue(e.frostThickness),
          'initial_note': e.initialNote,
          'measurements': _measurementsJson(e),
          'images_initial': e.initialPhotos.map((k, v) => MapEntry(k, v.toJson())),
          'images_after': e.afterPhotos.map((k, v) => MapEntry(k, v.toJson())),
        };
      }).toList();

      final result = await repository.submit(
        transNo: tx,
        createdBy: event.createdBy,
        createdByName: event.createdByName,
        createdByIp: event.createdByIP,
        info: info,
        items: items,
      );

      if (result['status'] == 'OK') {
        emit(PosfUploadInProgress());
        final presignedDetail =
            (result['result']?['detail'] as List<dynamic>?) ?? <dynamic>[];

        final uploadResult = await uploadProofOfServiceFreezerImagesToS3(
          tx,
          presignedDetail,
          progressCubit: event.progressCubit,
        );

        if (uploadResult.allSuccess) {
          await _confirmTaskDone(event.transNo);
          await _clearDrafts(event.transNo, entryBox, infoBox);
          emit(PosfSubmitSuccess());
        } else {
          final cleanFailed =
              uploadResult.failedFiles.map((f) => f.split(' (').first).toList();
          final cacheBox =
              await Hive.openBox<Map<dynamic, dynamic>>(kProofOfServiceFreezerPartialBox);
          await cacheBox.put(event.transNo, {
            'transNo': event.transNo,
            'failedFiles': cleanFailed,
            'presignedDetail': presignedDetail,
            'storeName': _storeName(event.transNo),
            'module': kProofOfServiceFreezerModuleType,
          });
          emit(PosfUploadPartial(
            successCount: uploadResult.successCount,
            failureCount: uploadResult.failureCount,
            failedFiles: cleanFailed,
            transNo: event.transNo,
          ));
        }
      } else {
        emit(PosfSubmitFailure(result['message']?.toString() ?? 'Submit gagal.'));
      }
    } catch (e) {
      emit(PosfSubmitFailure(e.toString()));
    }
  }

  /// Rakit `items[].measurements` sesuai kontrak submit.
  ///
  /// Suhu sebelum & sesudah pembersihan masuk ke SATU list dan dibedakan oleh
  /// `checked_status` (BEFORE/AFTER) dengan `measurement_id` yang sama
  /// ('temperature') — id lokal 'arrival_temp' tidak dikirim. Bukti kendala
  /// skip (alasan ber-flag require_remark) kini menempel di entri yang
  /// bersangkutan lewat `skip_remark` + `skip_photos`, bukan lagi field
  /// terpisah di level item.
  ///
  /// Unit "Tidak Terpakai"/"Freezer Tidak Bisa Dicuci" tidak diukur sama
  /// sekali (cubit mengosongkan datanya), jadi list-nya terkirim kosong.
  List<Map<String, dynamic>> _measurementsJson(
      ProofOfServiceFreezerEntryModel e) {
    final list = <Map<String, dynamic>>[];

    // BEFORE — suhu tiba. Hanya dikirim bila memang diisi atau di-skip.
    if (e.arrivalTempSkipped) {
      list.add(_measurementJson(
        checkedStatus: kPosfCheckedStatusBefore,
        measurementId: kPosfTempMeasurementId,
        value: 0,
        unit: kPosfArrivalTempLimit.unit,
        isSkipped: true,
        skipReason: e.arrivalTempReason ?? '',
        skipRemark: e.arrivalTempSkipRemark ?? '',
        image: null,
        skipPhotos: e.arrivalTempSkipPhotos,
      ));
    } else if (e.arrivalTemp != null) {
      list.add(_measurementJson(
        checkedStatus: kPosfCheckedStatusBefore,
        measurementId: kPosfTempMeasurementId,
        value: e.arrivalTemp!,
        unit: kPosfArrivalTempLimit.unit,
        isSkipped: false,
        image: e.arrivalTempImage,
      ));
    }

    // AFTER — pengukuran step Sesudah (saat ini hanya suhu).
    for (final m in e.measurements) {
      final skipped = m.isSkipped ?? false;
      list.add(_measurementJson(
        checkedStatus: kPosfCheckedStatusAfter,
        measurementId: m.measurementId,
        value: skipped ? 0 : m.value,
        unit: m.unit,
        isSkipped: skipped,
        skipReason: skipped ? (m.remark ?? '') : '',
        skipRemark: skipped ? _afterSkipRemark(e, m.measurementId) : '',
        image: skipped ? null : m.capturedImage,
        skipPhotos: skipped ? _afterSkipPhotos(e, m.measurementId) : null,
      ));
    }

    return list;
  }

  Map<String, dynamic> _measurementJson({
    required String checkedStatus,
    required String measurementId,
    required double value,
    required String unit,
    required bool isSkipped,
    String skipReason = '',
    String skipRemark = '',
    CapturedImageDetail? image,
    List<CapturedImageDetail>? skipPhotos,
  }) {
    return {
      'checked_status': checkedStatus,
      'measurement_id': measurementId,
      'value': value,
      'unit': unit,
      'is_skipped': isSkipped,
      'skip_reason': skipReason,
      'skip_remark': skipRemark,
      'image': image?.toJson(),
      'skip_photos':
          (skipPhotos ?? const []).map((p) => p.toJson()).toList(),
    };
  }

  // Bukti skip step Sesudah masih disimpan per GRUP di draft: 'temperature' ->
  // tempSkip*, 'ampere'/'volt' -> elecSkip* (grup listrik sudah tidak dipakai
  // wizard, dipertahankan agar draft lama tetap terbaca).
  bool _isElecMeasurement(String id) => id == 'ampere' || id == 'volt';

  String _afterSkipRemark(ProofOfServiceFreezerEntryModel e, String id) =>
      (_isElecMeasurement(id) ? e.elecSkipRemark : e.tempSkipRemark) ?? '';

  List<CapturedImageDetail> _afterSkipPhotos(
          ProofOfServiceFreezerEntryModel e, String id) =>
      (_isElecMeasurement(id) ? e.elecSkipPhotos : e.tempSkipPhotos) ??
      const [];

  /// Unit dari server (detail box) dipetakan per `unit_index`. Dipakai untuk
  /// melengkapi `unit_desc` & `line_no` yang tidak disimpan di draft. Bila
  /// cache detail hilang (mis. dibersihkan DailyHiveClearService), map kosong
  /// dan kedua field terkirim dengan nilai default.
  Future<Map<int, ProofOfServiceFreezerItem>> _serverUnits(
      String transNo) async {
    try {
      final box = Hive.isBoxOpen(kProofOfServiceFreezerDetailBox)
          ? Hive.box<ProofOfServiceFreezerDetailModel>(
              kProofOfServiceFreezerDetailBox)
          : await Hive.openBox<ProofOfServiceFreezerDetailModel>(
              kProofOfServiceFreezerDetailBox);
      final detail = box.get(_key(transNo));
      final units = detail?.items ?? const <ProofOfServiceFreezerItem>[];
      return {for (final u in units) u.unitIndex: u};
    } catch (_) {
      return {};
    }
  }

  String _storeName(String transNo) {
    try {
      if (Hive.isBoxOpen(kProofOfServiceFreezerDetailBox)) {
        return Hive.box<ProofOfServiceFreezerDetailModel>(kProofOfServiceFreezerDetailBox)
                .get(_key(transNo))
                ?.header
                ?.shipToName ??
            '';
      }
    } catch (_) {}
    return '';
  }

  /// Tandai task selesai di server (pola RRO/POS/SC). confirmUploadSuccess tidak
  /// pernah throw (mengembalikan {status:ERROR} bila gagal). Bila status != OK,
  /// antrikan ke ConfirmationService agar di-retry saat startup — cegah task
  /// nyangkut di pending walau draft sudah dibersihkan.
  Future<void> _confirmTaskDone(String transNo) async {
    final confirmResponse =
        await ServiceTaskRepository().confirmUploadSuccess(transNo);
    if (confirmResponse['status'] != 'OK') {
      final queueBox = Hive.isBoxOpen(kConfirmationQueueBox)
          ? Hive.box<ConfirmationTaskModel>(kConfirmationQueueBox)
          : await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
      await queueBox.put(transNo, ConfirmationTaskModel(transNo: transNo));
    }
  }

  Future<void> _clearDrafts(
    String transNo,
    Box<ProofOfServiceFreezerEntryModel> entryBox,
    Box<ProofOfServiceFreezerInfoModel> infoBox,
  ) async {
    final tx = transNo.trim().toUpperCase();
    final keys = entryBox.keys
        .where((k) => entryBox.get(k)?.transNo.trim().toUpperCase() == tx)
        .toList();
    await entryBox.deleteAll(keys);
    await infoBox.delete(_key(transNo));
  }
}

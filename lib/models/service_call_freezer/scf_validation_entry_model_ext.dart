// Pakai ulang ekstensi toJson() untuk CapturedImageDetail & MeasurementEntry
// yang sudah didefinisikan di modul Service Call (format payload identik).
import '../common/captured_image_detail.dart';
import '../service_call/service_call_validation_entry_model_ext.dart';
import 'scf_validation_entry_model.dart';

extension ScfValidationEntryModelJson on ScfValidationEntryModel {
  /// Serialisasi 1 item freezer untuk payload submit.
  ///
  /// SCF submit memakai endpoint Service Call `/service_call/validation/submitted/v4`,
  /// jadi bentuknya HARUS mengikuti `ItemDetail` milik SC — bukan skema freezer
  /// sendiri. Pemetaan yang disepakati:
  ///
  /// - grup suhu        → slot `indoor`  (SC: unit indoor)
  /// - grup kelistrikan → slot `outdoor` (SC: unit outdoor)
  /// - slot `psi`       → selalu kosong (freezer tidak mengukur tekanan)
  ///
  /// Format SC yang berjalan HANYA punya satu kolom remark per grup — tidak ada
  /// varian `_before`. Keterangan & foto bukti fase Sebelum digabung ke kolom
  /// tersebut (lihat catatan di bagian remark di bawah).
  ///
  /// Foto unit dikirim sebagai ARRAY objek penuh (`image_file_name` + timestamp
  /// + lat/long + device) — bentuk `images_before`/`images_after` milik SC —
  /// tapi tiap elemen ditambahi `slot` (front/inside/condenser) supaya backend
  /// bisa menyimpannya sebagai Type per posisi pengambilan.
  ///
  /// Field kondisi freezer (arrival_temp*, general_condition, complaint,
  /// condition_note/photos, frost_thickness) SENGAJA tidak dikirim: semuanya
  /// sudah selalu kosong sejak kondisi freezer dihapus dari wizard SCF.
  /// `initialNote` tetap dibawa lewat `note_remark` supaya catatan teknisi
  /// tidak hilang.
  Map<String, dynamic> toJson() {
    return {
      'trans_no': transNo,
      'serial_no': serialNo,
      // Freezer tidak punya alur koreksi serial maupun unit outdoor.
      'correct_serial_no': '',
      'outdoor_serial_no': '',
      'unit_type': unitType,

      // --- Alasan skip per grup (hanya terisi bila grupnya di-skip) ---
      'note_indoor_before':
          _tempSkipped(measurementsBefore) ? (selectedTempNoteBefore ?? '') : '',
      'note_indoor_after':
          _tempSkipped(measurementsAfter) ? (selectedTempNoteAfter ?? '') : '',
      'note_outdoor_before':
          _elecSkipped(measurementsBefore) ? (selectedElecNoteBefore ?? '') : '',
      'note_outdoor_after':
          _elecSkipped(measurementsAfter) ? (selectedElecNoteAfter ?? '') : '',
      'note_outdoor_psi_before': '',
      'note_outdoor_psi_after': '',

      // --- Keterangan + foto bukti kendala ---
      // `ItemDetail` SC hanya punya SATU kolom remark per grup (tidak ada varian
      // `_before`), sedangkan SCF mengumpulkan keterangan & bukti untuk fase
      // Sebelum DAN Sesudah. Keduanya digabung ke kolom yang ada supaya tidak
      // ada yang hilang — lihat [_mergeRemark].
      //
      // CATATAN: konsekuensinya foto bukti fase Sebelum ikut tersimpan sebagai
      // baris `remark_indoor`/`remark_outdoor` ber-`checked_status = AFTER`,
      // karena itu satu-satunya slot yang disediakan format SC. Alasan skip-nya
      // sendiri tetap terpisah per fase lewat `note_indoor_before`/`_after`.
      'note_remark': initialNote ?? '',
      'note_remark_indoor':
          _mergeRemark(tempSkipRemarkBefore, tempSkipRemarkAfter),
      'note_remark_outdoor':
          _mergeRemark(elecSkipRemarkBefore, elecSkipRemarkAfter),
      'note_remark_psi': '',
      'remark_photos_indoor': [
        ...?tempSkipPhotosBefore,
        ...?tempSkipPhotosAfter,
      ].map((img) => img.toJson()).toList(),
      'remark_photos_outdoor': [
        ...?elecSkipPhotosBefore,
        ...?elecSkipPhotosAfter,
      ].map((img) => img.toJson()).toList(),
      'remark_photos_psi': [],

      // --- Foto unit, per slot pengambilan ---
      // Tiap foto membawa `slot` (front/inside/condenser). Backend memakainya
      // sebagai kolom Type dan segmen S3 key, jadi tiap foto tersimpan sesuai
      // posisi pengambilannya — bukan "unit" untuk semuanya. Service Call AC
      // tidak mengirim `slot`, jadi di sana Type tetap "unit" seperti biasa.
      'images_before': _withSlot(initialPhotos),
      'images_after': _withSlot(afterPhotos),

      // --- Pengukuran ---
      'measurements_before': measurementsBefore.map((m) => m.toJson()).toList(),
      'measurements_after': measurementsAfter.map((m) => m.toJson()).toList(),

      // --- Permasalahan & Solusi ---
      'problems': problems.map((p) => p.toJson()).toList(),
    };
  }

  /// Ubah map slot→foto jadi array objek foto, masing-masing membawa id slot-nya
  /// di key `slot`. Bentuk array mengikuti `images_before`/`images_after` milik
  /// Service Call; `slot` adalah tambahan opsional yang hanya dikirim freezer.
  List<Map<String, dynamic>> _withSlot(Map<String, CapturedImageDetail> slots) {
    return slots.entries
        .map((e) => {...e.value.toJson(), 'slot': e.key})
        .toList();
  }

  /// Gabungkan keterangan skip fase Sebelum & Sesudah jadi satu teks.
  /// Diberi label hanya bila DUA-DUANYA terisi; kasus umum (cuma salah satu
  /// fase yang di-skip) tetap terkirim apa adanya tanpa awalan.
  String _mergeRemark(String? before, String? after) {
    final b = (before ?? '').trim();
    final a = (after ?? '').trim();
    if (b.isEmpty) return a;
    if (a.isEmpty) return b;
    return 'Sebelum: $b | Sesudah: $a';
  }

  bool _tempSkipped(List measurements) => measurements.any((m) =>
      m.measurementId.toLowerCase().contains('temperature') &&
      (m.isSkipped ?? false));

  bool _elecSkipped(List measurements) => measurements.any((m) =>
      !m.measurementId.toLowerCase().contains('temperature') &&
      (m.isSkipped ?? false));
}

extension ScfValidationProblemJson on ScfValidationProblem {
  Map<String, dynamic> toJson() {
    return {
      'problem_id': problemId,
      'solution_ids': solutionIds,
    };
  }
}

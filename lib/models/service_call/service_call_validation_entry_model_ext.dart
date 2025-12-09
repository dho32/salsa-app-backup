import 'package:intl/intl.dart';

import '../common/captured_image_detail.dart';
import '../common/measurement_entry.dart';
import 'service_call_validation_entry_model.dart';

extension ServiceCallValidationEntryModelJson
    on ServiceCallValidationEntryModel {
  Map<String, dynamic> toJson() {
    // Cek status skip untuk "SEBELUM"
    final bool isIndoorBeforeSkipped = measurementsBefore.any((m) =>
        m.measurementId.toLowerCase().contains('temperature') &&
        (m.isSkipped ?? false));

    final bool isOutdoorBeforeSkipped = measurementsBefore.any((m) =>
        !m.measurementId.toLowerCase().contains('temperature') &&
        (m.isSkipped ?? false));

    // Cek status skip untuk "SESUDAH"
    final bool isIndoorAfterSkipped = measurementsAfter.any((m) =>
        m.measurementId.toLowerCase().contains('temperature') &&
        (m.isSkipped ?? false));

    final bool isOutdoorAfterSkipped = measurementsAfter.any((m) =>
        !m.measurementId.toLowerCase().contains('temperature') &&
        (m.isSkipped ?? false));

    // --- AKHIR LOGIKA BARU ---
    return {
      'serial_no': serialNo,
      'outdoor_serial_no': outdoorSerialNo,
      'unit_type': unitType,
      'problems': problems.map((p) => p.toJson()).toList(),
      'images_before': imagePathsBefore.map((img) => img.toJson()).toList(),
      'measurements_before': measurementsBefore.map((m) => m.toJson()).toList(),
      'images_after': imagePathsAfter.map((img) => img.toJson()).toList(),
      'measurements_after': measurementsAfter.map((m) => m.toJson()).toList(),
      'trans_no': transNo,
      'note_indoor_before':
          isIndoorBeforeSkipped ? selectedIndoorNoteBefore : "",
      'note_indoor_after': isIndoorAfterSkipped ? selectedIndoorNoteAfter : "",
      'note_outdoor_before':
          isOutdoorBeforeSkipped ? selectedOutdoorNoteBefore : "",
      'note_outdoor_after':
          isOutdoorAfterSkipped ? selectedOutdoorNoteAfter : "",
      'note_outdoor_psi_before':
          isOutdoorBeforeSkipped ? selectedOutdoorPSINoteBefore : "",
      'note_outdoor_psi_after':
          isOutdoorAfterSkipped ? selectedOutdoorPSINoteAfter : "",
      'correct_serial_no': correctSerialNo ?? '',
      'note_remark': noteRemark ?? '',
      'note_remark_indoor': noteRemarkIndoor ?? '',
      'note_remark_outdoor': noteRemarkOutdoor ?? '',
      'note_remark_psi': noteRemarkPSI ?? '',
      'remark_photos_indoor': remarkPhotosIndoorAfter?.map((img) => img.toJson()).toList() ?? [],
      'remark_photos_outdoor': remarkPhotosOutdoorAfter?.map((img) => img.toJson()).toList() ?? [],
      'remark_photos_psi': remarkPhotosOutdoorPsiAfter?.map((img) => img.toJson()).toList() ?? [],
    };
  }
}

extension ValidationProblemJson on ValidationProblem {
  Map<String, dynamic> toJson() {
    return {
      'problem_id': problemId,
      'solution_ids': solutionIds,
    };
  }
}

// BARU: Tambahkan ekstensi untuk CapturedImageDetail
extension CapturedImageDetailJson on CapturedImageDetail {
  Map<String, dynamic> toJson() {
    return {
      'image_file_name': imagePath.split('/').last,
      // Hanya kirim nama file
      'timestamp': DateFormat("yyyy-MM-dd HH:mm:ss").format(timestamp),
      // Format timestamp
      'latitude': latitude,
      'longitude': longitude,
      'device': deviceModel,
    };
  }
}

// BARU: Tambahkan ekstensi untuk MeasurementEntry
extension MeasurementEntryJson on MeasurementEntry {
  Map<String, dynamic> toJson() {
    return {
      'measurement_id': measurementId,
      'value': isSkipped ?? false ? 0 : value,
      'unit': unit,
      'image': isSkipped ?? false ? null : capturedImage?.toJson(),
      'is_skipped': isSkipped,
    };
  }
}

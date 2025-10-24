import 'package:intl/intl.dart';

import '../common/captured_image_detail.dart';
import '../common/measurement_entry.dart';
import 'service_call_validation_entry_model.dart';

extension ServiceCallValidationEntryModelJson on ServiceCallValidationEntryModel {
  Map<String, dynamic> toJson() {
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
      'note_indoor_before': selectedIndoorNoteBefore,
      'note_indoor_after': selectedIndoorNoteAfter,
      'note_outdoor_before': selectedOutdoorNoteBefore,
      'note_outdoor_after': selectedOutdoorNoteAfter,
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
      'image_file_name': imagePath.split('/').last, // Hanya kirim nama file
      'timestamp': DateFormat("yyyy-MM-dd HH:mm:ss").format(timestamp), // Format timestamp
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
      'value': isSkipped?0:value,
      'unit': unit,
      'image': isSkipped?null:capturedImage?.toJson(),
      'is_skipped': isSkipped,
    };
  }
}

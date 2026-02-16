import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model_ext.dart';

extension PosValidationEntryModelJson on PosValidationEntryModel {
  Map<String, dynamic> toJson() {
    // Logic existing: Note hanya dikirim jika ada pengukuran yang di-skip
    final bool isAnyMeasurementSkipped = measurementsAfter.any((m) => m.isSkipped ?? false);

    return {
      'serial_no': serialNo,
      'article_no': articleNo,
      'article_desc': articleDesc,
      'article_unit_desc': articleUnitDesc,
      'article_type': articleType,
      'note': isAnyMeasurementSkipped ? note : "",
      'remark': noteRemark,
      'remark_photos': remarkPhotos?.map((img) => img.toJson()).toList(),
      'images_before': photosBefore.map((img) => img.toJson()).toList(),
      'images_after': photosAfter.map((img) => img.toJson()).toList(),
      'measurements_after': measurementsAfter.map((m) => m.toJson()).toList(),
      'paired_serial_no': pairedSerialNo,
      'reff_line_no': reffLineNo,
    };
  }
}
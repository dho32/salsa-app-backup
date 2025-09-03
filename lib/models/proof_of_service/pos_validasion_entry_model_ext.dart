
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model_ext.dart';

extension PosValidationEntryModelJson on PosValidationEntryModel {
  Map<String, dynamic> toJson() {
    return {
      'serial_no': serialNo,
      'article_no': articleNo,
      'article_desc': articleDesc,
      'article_unit_desc': articleUnitDesc,
      'article_type': articleType,
      'note': note,
      'images_before': photosBefore.map((img) => img.toJson()).toList(),
      'images_after': photosAfter.map((img) => img.toJson()).toList(),
      'measurements_after': measurementsAfter.map((m) => m.toJson()).toList(),
    };
  }
}
import 'package:hive/hive.dart';

import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../../../components/constants.dart';
import '../../../../../models/common/captured_image_detail.dart';
import '../../../../../models/common/measurement_entry.dart';
import '../../../../../models/service_call/service_call_validation_entry_model.dart';

Future<void> saveValidationToHive({
  required String transNo,
  required String unitType,
  required String serialNo,
  required List<CapturedImageDetail> imagePathsBefore,
  required List<MeasurementEntry> measurementsBefore,
  required List<SelectedProblemCard> selectedProblemCardsAfter,
  required List<CapturedImageDetail> imagePathsAfter,
  required List<MeasurementEntry> measurementsAfter,
}) async {
  final box = Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);

  // Konversi SelectedProblemCard ke ValidationProblem untuk data "Sesudah"
  final problemsAfter = selectedProblemCardsAfter
      .where((card) =>
          card.selectedProblemId != null && card.selectedSolutionIds.isNotEmpty)
      .map((card) => ValidationProblem(
            problemId: card.selectedProblemId!,
            solutionIds: card.selectedSolutionIds,
          ))
      .toList();

  final entry = ServiceCallValidationEntryModel(
    unitType: unitType,
    serialNo: serialNo,
    transNo: transNo,
    // Pastikan transNo ada di konstruktor model
    imagePathsBefore: imagePathsBefore,
    // BARU
    measurementsBefore: measurementsBefore,
    // BARU
    problems: problemsAfter,
    // MODIFIKASI: Gunakan problemsAfter
    imagePathsAfter: imagePathsAfter,
    // BARU
    measurementsAfter: measurementsAfter, // BARU
  );

  // Cek apakah data untuk serialNo ini sudah ada, jika ada update, jika tidak add baru
  final existingKey = box.keys.cast<int?>().firstWhere(
        (key) =>
            box.get(key)?.serialNo == serialNo &&
            box.get(key)?.transNo == transNo, // Periksa transNo juga
        orElse: () => null,
      );

  if (existingKey != null) {
    await box.put(existingKey, entry);
  } else {
    await box.add(entry);
  }
}

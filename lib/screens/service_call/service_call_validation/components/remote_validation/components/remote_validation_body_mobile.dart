import 'package:flutter/material.dart';
import 'package:salsa/models/service_call/problem_source_model.dart';
import 'package:salsa/blocs/service_call/validation_dropdown/validation_dropdown_state.dart'; // kita butuh SelectedProblemCard
import 'package:salsa/screens/service_call/service_call_validation/components/widgets/service_call_validation_widgets.dart';

class RemoteValidationBodyMobile extends StatelessWidget {
  // Terima semua data dan fungsi dari parent
  final bool isLoading;
  final List<ProblemSourceModel> problemSources;
  final String? selectedUnitType;
  final List<SelectedProblemCard> selectedProblemCards;
  final String transNo;
  final String uniqueId;
  final String complaintDetails;
  final String imageFile;
  final ValueChanged<String?> onUnitTypeChanged;
  final VoidCallback onAddProblem;
  final ValueChanged<SelectedProblemCard> onRemoveProblem;


  const RemoteValidationBodyMobile({
    super.key,
    required this.isLoading,
    required this.problemSources,
    this.selectedUnitType,
    required this.selectedProblemCards,
    required this.transNo,
    required this.uniqueId,
    required this.complaintDetails,
    required this.imageFile,
    required this.onUnitTypeChanged,
    required this.onAddProblem,
    required this.onRemoveProblem,
  });

  @override
  Widget build(BuildContext context) {
    final problemsForSelectedType = selectedUnitType == null
        ? <Problem>[]
        : problemSources
        .firstWhere((s) => s.unitType == selectedUnitType, orElse: () => ProblemSourceModel(unitType: '', problems: []))
        .problems;

    // Body tidak lagi punya Scaffold, hanya kontennya saja
    return SingleChildScrollView(
      child: Column(
        children: [
          HeaderInfo(
            transNo: transNo,
            serialNo: uniqueId,
            lineNo: '',
            complaintDetails: complaintDetails,
            imageFile: imageFile,
          ),
          if (!isLoading) ...[
            buildUnitTypeSelector(
              context: context,
              groupValue: selectedUnitType,
              onChanged: onUnitTypeChanged, // Panggil callback dari parent
            ),
            buildProblemCards(
              context: context,
              state: ValidationDropdownLoaded( // Beri data dummy yg dibutuhkan
                data: [],
                selectedProblemCards: selectedProblemCards,
              ),
              problemsForType: problemsForSelectedType,
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 64.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
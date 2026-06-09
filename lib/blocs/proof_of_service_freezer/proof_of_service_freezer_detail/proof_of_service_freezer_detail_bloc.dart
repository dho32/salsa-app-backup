import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_entry_model.dart';
import 'proof_of_service_freezer_detail_repository.dart';

part 'proof_of_service_freezer_detail_event.dart';
part 'proof_of_service_freezer_detail_state.dart';

/// Key Hive per-freezer yang dipakai bersama oleh detail bloc & wizard validasi.
/// - generic : `GEN_<transNo>_<unitIndex>`
/// - serial  : `serialNo.trim().toUpperCase()`
String freezerEntryKey(String transNo, String serialNo, bool isGeneric, int unitIndex) {
  if (isGeneric) {
    return 'GEN_${transNo.trim().toUpperCase()}_$unitIndex';
  }
  return serialNo.trim().toUpperCase();
}

class ProofOfServiceFreezerDetailBloc
    extends Bloc<ProofOfServiceFreezerDetailEvent, ProofOfServiceFreezerDetailState> {
  final ProofOfServiceFreezerDetailRepository repository;

  ProofOfServiceFreezerDetailBloc({required this.repository})
      : super(ProofOfServiceFreezerDetailInitial()) {
    on<FetchProofOfServiceFreezerDetail>(_onFetch);
  }

  Future<void> _onFetch(
    FetchProofOfServiceFreezerDetail event,
    Emitter<ProofOfServiceFreezerDetailState> emit,
  ) async {
    emit(ProofOfServiceFreezerDetailLoading());
    try {
      final data = await repository.getDetail(event.transNo);

      // Cache ke Hive (read-only), supaya tetap bisa dibuka offline.
      if (Hive.isBoxOpen(kProofOfServiceFreezerDetailBox)) {
        await Hive.box<ProofOfServiceFreezerDetailModel>(kProofOfServiceFreezerDetailBox)
            .put(event.transNo.trim().toUpperCase(), data);
      }

      final statuses = _calculateStatuses(event.transNo, data);
      final allValidated = data.items.isNotEmpty &&
          statuses.values.every((s) => s == FreezerValidationStatus.completed);

      emit(ProofOfServiceFreezerDetailLoaded(
        data: data,
        statuses: statuses,
        allUnitsValidated: allValidated,
      ));
    } catch (e) {
      emit(ProofOfServiceFreezerDetailError(e.toString()));
    }
  }

  Map<String, FreezerValidationStatus> _calculateStatuses(
    String transNo,
    ProofOfServiceFreezerDetailModel data,
  ) {
    final result = <String, FreezerValidationStatus>{};
    Box<ProofOfServiceFreezerEntryModel>? entryBox;
    if (Hive.isBoxOpen(kProofOfServiceFreezerEntryBox)) {
      entryBox = Hive.box<ProofOfServiceFreezerEntryModel>(kProofOfServiceFreezerEntryBox);
    }
    for (final item in data.items) {
      final key =
          freezerEntryKey(transNo, item.serialNo, item.isGeneric, item.unitIndex);
      final entry = entryBox?.get(key);
      if (entry == null) {
        result[key] = FreezerValidationStatus.notStarted;
      } else if (entry.isCompleted) {
        result[key] = FreezerValidationStatus.completed;
      } else {
        result[key] = FreezerValidationStatus.inProgress;
      }
    }
    return result;
  }
}

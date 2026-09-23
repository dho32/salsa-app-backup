import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../models/service_call_freezer/scf_validation_entry_model.dart';
import '../../../models/service_call_freezer/service_call_freezer_detail_model.dart';
import 'scf_detail_repository.dart';

part 'scf_detail_event.dart';
part 'scf_detail_state.dart';

class ScfDetailBloc extends Bloc<ScfDetailEvent, ScfDetailState> {
  final ScfDetailRepository repository;

  /// Vendor teknisi (`userData['maintenance_by']`) — konstan selama layar hidup,
  /// jadi disimpan di bloc dan bukan di event, supaya seluruh refetch yang sudah
  /// ada (mis. setelah kembali dari wizard) ikut mengirimnya tanpa diubah.
  final String vendorId;

  ScfDetailBloc({required this.repository, this.vendorId = ''})
      : super(ScfDetailInitial()) {
    on<FetchScfDetail>(_onFetch);
  }

  Future<void> _onFetch(
    FetchScfDetail event,
    Emitter<ScfDetailState> emit,
  ) async {
    emit(ScfDetailLoading());
    try {
      final data =
          await repository.getDetail(event.transNo, vendorId: vendorId);

      // Cache ke box detail (untyped) sebagai JSON — read-only, tetap bisa
      // dibuka offline. Box ini menyimpan Map, bukan model bertipe.
      if (Hive.isBoxOpen(kServiceCallFreezerDetailBox)) {
        await Hive.box(kServiceCallFreezerDetailBox)
            .put(event.transNo.trim().toUpperCase(), data.toJson());
      }

      final statuses = _calculateStatuses(event.transNo, data);
      final allValidated = data.units.isNotEmpty &&
          statuses.values.every((s) => s == ScfValidationStatus.completed);

      emit(ScfDetailLoaded(
        data: data,
        statuses: statuses,
        allUnitsValidated: allValidated,
      ));
    } catch (e) {
      emit(ScfDetailError(e.toString()));
    }
  }

  Map<String, ScfValidationStatus> _calculateStatuses(
    String transNo,
    ServiceCallFreezerDetailModel data,
  ) {
    final result = <String, ScfValidationStatus>{};
    Box<ScfValidationEntryModel>? entryBox;
    if (Hive.isBoxOpen(kServiceCallFreezerEntryBox)) {
      entryBox = Hive.box<ScfValidationEntryModel>(kServiceCallFreezerEntryBox);
    }
    for (final unit in data.units) {
      final key =
          scfEntryKey(transNo, unit.serialNo, unit.isGeneric, unit.unitIndex);
      final entry = entryBox?.get(key);
      if (entry == null) {
        result[key] = ScfValidationStatus.notStarted;
      } else if (entry.isCompleted) {
        result[key] = ScfValidationStatus.completed;
      } else {
        result[key] = ScfValidationStatus.inProgress;
      }
    }
    return result;
  }
}

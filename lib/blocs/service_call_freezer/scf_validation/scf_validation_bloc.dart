import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/service_call/problem_source_model.dart';

part 'scf_validation_event.dart';
part 'scf_validation_state.dart';

/// Bloc pemilih Permasalahan & Solusi (freezer). Mirror
/// `ServiceCallValidationBloc` (SC): dari master [ProblemSourceModel] ia
/// memfilter daftar problem per unit type lalu daftar solusi per cause.
///
/// Dipakai opsional oleh UI Permasalahan & Solusi; wizard utama
/// ([ScfValidationDropdownCubit]) sendiri menyimpan pilihan card ke Hive.
class ScfValidationBloc extends Bloc<ScfValidationEvent, ScfValidationState> {
  ScfValidationBloc() : super(ScfValidationInitial()) {
    on<LoadScfProblemSources>(_onLoad);
    on<SelectScfUnitType>(_onSelectUnitType);
    on<SelectScfProblem>(_onSelectProblem);
  }

  void _onLoad(LoadScfProblemSources event, Emitter<ScfValidationState> emit) {
    emit(ScfValidationLoaded(sources: event.sources));
  }

  void _onSelectUnitType(
      SelectScfUnitType event, Emitter<ScfValidationState> emit) {
    if (state is! ScfValidationLoaded) return;
    final s = state as ScfValidationLoaded;
    final source =
        s.sources.firstWhereOrNull((src) => src.unitType == event.unitType);
    emit(s.copyWith(
      selectedUnitType: event.unitType,
      problems: source?.problems ?? const [],
      selectedCauseId: null,
      solutions: const [],
    ));
  }

  void _onSelectProblem(
      SelectScfProblem event, Emitter<ScfValidationState> emit) {
    if (state is! ScfValidationLoaded) return;
    final s = state as ScfValidationLoaded;
    final problem =
        s.problems.firstWhereOrNull((p) => p.causeId == event.causeId);
    emit(s.copyWith(
      selectedCauseId: event.causeId,
      solutions: problem?.solutions ?? const [],
    ));
  }
}

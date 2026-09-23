part of 'scf_validation_bloc.dart';

abstract class ScfValidationEvent extends Equatable {
  const ScfValidationEvent();

  @override
  List<Object?> get props => [];
}

/// Muat master Permasalahan & Solusi (dari detail) ke dalam bloc.
class LoadScfProblemSources extends ScfValidationEvent {
  final List<ProblemSourceModel> sources;

  const LoadScfProblemSources(this.sources);

  @override
  List<Object?> get props => [sources];
}

/// Pilih tipe unit → memfilter daftar problem.
class SelectScfUnitType extends ScfValidationEvent {
  final String unitType;

  const SelectScfUnitType(this.unitType);

  @override
  List<Object?> get props => [unitType];
}

/// Pilih problem (cause) → memunculkan daftar solusi.
class SelectScfProblem extends ScfValidationEvent {
  final String causeId;

  const SelectScfProblem(this.causeId);

  @override
  List<Object?> get props => [causeId];
}

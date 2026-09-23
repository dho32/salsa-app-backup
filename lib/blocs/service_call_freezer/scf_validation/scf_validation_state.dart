part of 'scf_validation_bloc.dart';

abstract class ScfValidationState extends Equatable {
  const ScfValidationState();

  @override
  List<Object?> get props => [];
}

class ScfValidationInitial extends ScfValidationState {}

class ScfValidationLoading extends ScfValidationState {}

class ScfValidationLoaded extends ScfValidationState {
  final List<ProblemSourceModel> sources;
  final String? selectedUnitType;
  final List<Problem> problems;
  final String? selectedCauseId;
  final List<Solution> solutions;

  const ScfValidationLoaded({
    required this.sources,
    this.selectedUnitType,
    this.problems = const [],
    this.selectedCauseId,
    this.solutions = const [],
  });

  ScfValidationLoaded copyWith({
    String? selectedUnitType,
    List<Problem>? problems,
    String? selectedCauseId,
    List<Solution>? solutions,
  }) {
    return ScfValidationLoaded(
      sources: sources,
      selectedUnitType: selectedUnitType ?? this.selectedUnitType,
      problems: problems ?? this.problems,
      selectedCauseId: selectedCauseId ?? this.selectedCauseId,
      solutions: solutions ?? this.solutions,
    );
  }

  @override
  List<Object?> get props =>
      [sources, selectedUnitType, problems, selectedCauseId, solutions];
}

class ScfValidationErrorState extends ScfValidationState {
  final String message;

  const ScfValidationErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

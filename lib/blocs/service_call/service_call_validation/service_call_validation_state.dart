import 'package:equatable/equatable.dart';

import '../../../models/service_call/problem_source_model.dart';

abstract class ServiceCallValidationState extends Equatable {
  const ServiceCallValidationState();

  @override
  List<Object?> get props => [];
}

class ValidationInitial extends ServiceCallValidationState {}

class ValidationLoading extends ServiceCallValidationState {}

class ValidationLoaded extends ServiceCallValidationState {
  final List<ProblemSourceModel> sources;
  final String? selectedUnitType;
  final List<Problem> problems;
  final String? selectedCauseId;
  final List<Solution> solutions;

  const ValidationLoaded({
    required this.sources,
    this.selectedUnitType,
    this.problems = const [],
    this.selectedCauseId,
    this.solutions = const [],
  });

  ValidationLoaded copyWith({
    String? selectedUnitType,
    List<Problem>? problems,
    String? selectedCauseId,
    List<Solution>? solutions,
  }) {
    return ValidationLoaded(
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

class ValidationError extends ServiceCallValidationState {
  final String message;

  const ValidationError(this.message);

  @override
  List<Object?> get props => [message];
}


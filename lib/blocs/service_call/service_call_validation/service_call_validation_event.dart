// service_call_validation_event.dart
import 'package:equatable/equatable.dart';

abstract class ServiceCallValidationEvent extends Equatable {
  const ServiceCallValidationEvent();

  @override
  List<Object?> get props => [];
}

class LoadValidationData extends ServiceCallValidationEvent {}

class SelectUnitType extends ServiceCallValidationEvent {
  final String unitType;
  const SelectUnitType(this.unitType);

  @override
  List<Object?> get props => [unitType];
}

class SelectProblem extends ServiceCallValidationEvent {
  final String causeId;
  const SelectProblem(this.causeId);

  @override
  List<Object?> get props => [causeId];
}



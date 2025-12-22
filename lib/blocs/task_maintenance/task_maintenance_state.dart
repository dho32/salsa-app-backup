import 'package:equatable/equatable.dart';
import '../../models/task_maintenance/task_maintenance_model.dart';

abstract class TaskMaintenanceState extends Equatable {
  const TaskMaintenanceState();
  @override
  List<Object> get props => [];
}
class POSearchInitial extends TaskMaintenanceState {}
class POSearchLoading extends TaskMaintenanceState {}
class POSearchSuccess extends TaskMaintenanceState {
  final List<TransactionSuggestion> suggestions;
  const POSearchSuccess(this.suggestions);

  @override
  List<Object> get props => [suggestions];
}
class POSearchFailure extends TaskMaintenanceState {
  final String message;
  const POSearchFailure(this.message);

  @override
  List<Object> get props => [message];
}

class TaskListLoaded extends TaskMaintenanceState {
  final List<TransactionSuggestion> tasks; // List dari API
  const TaskListLoaded(this.tasks);
}
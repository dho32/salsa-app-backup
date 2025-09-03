import 'package:equatable/equatable.dart';
import '../../models/task_maintenance/task_maintenance_model.dart';

abstract class POSearchState extends Equatable {
  const POSearchState();
  @override
  List<Object> get props => [];
}
class POSearchInitial extends POSearchState {}
class POSearchLoading extends POSearchState {}
class POSearchSuccess extends POSearchState {
  final List<TransactionSuggestion> suggestions;
  const POSearchSuccess(this.suggestions);

  @override
  List<Object> get props => [suggestions];
}
class POSearchFailure extends POSearchState {
  final String message;
  const POSearchFailure(this.message);

  @override
  List<Object> get props => [message];
}
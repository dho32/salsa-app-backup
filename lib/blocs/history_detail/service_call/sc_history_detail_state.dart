// blocs/history/sc_history_detail_state.dart
import 'package:equatable/equatable.dart';
import 'package:salsa/models/history/sc_history_detail_model.dart';

abstract class ScHistoryDetailState extends Equatable {
  const ScHistoryDetailState();
  @override
  List<Object> get props => [];
}

class ScHistoryDetailInitial extends ScHistoryDetailState {}

class ScHistoryDetailLoading extends ScHistoryDetailState {}

class ScHistoryDetailLoaded extends ScHistoryDetailState {
  final ScHistoryDetailModel data;

  const ScHistoryDetailLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class ScHistoryDetailError extends ScHistoryDetailState {
  final String message;

  const ScHistoryDetailError(this.message);

  @override
  List<Object> get props => [message];
}
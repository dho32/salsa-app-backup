import 'package:equatable/equatable.dart';
import 'package:salsa/models/history/pos_history_detail_model.dart';

abstract class PosHistoryDetailState extends Equatable {
  const PosHistoryDetailState();

  @override
  List<Object> get props => [];
}

class PosHistoryDetailInitial extends PosHistoryDetailState {}

class PosHistoryDetailLoading extends PosHistoryDetailState {}

class PosHistoryDetailLoaded extends PosHistoryDetailState {
  final PosHistoryDetailModel data;

  const PosHistoryDetailLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class PosHistoryDetailError extends PosHistoryDetailState {
  final String message;

  const PosHistoryDetailError(this.message);

  @override
  List<Object> get props => [message];
}

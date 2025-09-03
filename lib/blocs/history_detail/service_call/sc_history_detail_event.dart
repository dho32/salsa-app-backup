// blocs/history/sc_history_detail_event.dart
import 'package:equatable/equatable.dart';

abstract class ScHistoryDetailEvent extends Equatable {
  const ScHistoryDetailEvent();
  @override
  List<Object> get props => [];
}

class FetchScHistoryDetail extends ScHistoryDetailEvent {
  final String transNo;

  const FetchScHistoryDetail(this.transNo);

  @override
  List<Object> get props => [transNo];
}
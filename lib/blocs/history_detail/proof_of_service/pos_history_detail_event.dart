import 'package:equatable/equatable.dart';

abstract class PosHistoryDetailEvent extends Equatable {
  const PosHistoryDetailEvent();

  @override
  List<Object> get props => [];
}

class FetchPosHistoryDetail extends PosHistoryDetailEvent {
  final String transNo;

  const FetchPosHistoryDetail(this.transNo);

  @override
  List<Object> get props => [transNo];
}

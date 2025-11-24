import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

// Event untuk mengambil data (bisa dipicu oleh refresh atau scroll)
class HistoryFetched extends HistoryEvent {}

// Event untuk refresh atau saat filter berubah
class HistoryRefreshed extends HistoryEvent {
  final String? searchQuery;
  final String? transactionType;
  final String? status;

  const HistoryRefreshed({this.searchQuery, this.transactionType, this.status});
}

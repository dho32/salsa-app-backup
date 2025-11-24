import 'package:equatable/equatable.dart';
import 'package:salsa/models/history/history_transaction_model.dart';

enum HistoryStatus { initial, success, failure, loading }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<HistoryTransactionModel> transactions;
  final bool hasReachedMax;
  final int page;
  final String searchQuery;
  final String transactionType;
  final String filterStatus;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.transactions = const <HistoryTransactionModel>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.searchQuery = '',
    this.transactionType = 'ALL',
    this.filterStatus = 'ALL',
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<HistoryTransactionModel>? transactions,
    bool? hasReachedMax,
    int? page,
    String? searchQuery,
    String? transactionType,
    String? filterStatus,
  }) {
    return HistoryState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      transactionType: transactionType ?? this.transactionType,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  @override
  List<Object> get props => [
        status,
        transactions,
        hasReachedMax,
        page,
        searchQuery,
        transactionType,
        filterStatus
      ];
}

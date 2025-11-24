import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/blocs/history/history_event.dart';
import 'package:salsa/blocs/history/history_state.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import 'history_repository.dart';

const _postLimit = 5; // Sesuai kode Anda

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository repository;

  HistoryBloc(this.repository) : super(const HistoryState()) {
    on<HistoryFetched>(_onHistoryFetched, transformer: droppable());
    on<HistoryRefreshed>(_onHistoryRefreshed);
  }

  Future<void> _onHistoryFetched(
      HistoryFetched event, Emitter<HistoryState> emit) async {
    if (state.hasReachedMax) return;
    try {
      final userData = await AuthStorage.getUser();
      final userId = userData['user_id'] ?? '';

      final transactions = await repository.fetchHistory(
        page: state.page,
        userId: userId,
        searchQuery: state.searchQuery,
        transactionType: state.transactionType,
        status: state.filterStatus,
      );

      emit(transactions.isEmpty
          ? state.copyWith(hasReachedMax: true)
          : state.copyWith(
              status: HistoryStatus.success,
              transactions: List.of(state.transactions)..addAll(transactions),
              hasReachedMax: transactions.length < _postLimit,
              page: state.page + 1,
            ));
    } catch (_) {
      emit(state.copyWith(status: HistoryStatus.failure));
    }
  }

  Future<void> _onHistoryRefreshed(
      HistoryRefreshed event, Emitter<HistoryState> emit) async {
    // 1. Tentukan nilai filter final dengan menggabungkan event dan state
    final newSearchQuery = event.searchQuery ?? state.searchQuery;
    final newTransactionType = event.transactionType ?? state.transactionType;
    final newStatus = event.status ?? state.filterStatus;

    // 2. Pancarkan state loading dengan filter yang sudah digabung
    emit(const HistoryState().copyWith(
      status: HistoryStatus.loading,
      searchQuery: newSearchQuery,
      transactionType: newTransactionType,
      filterStatus: newStatus,
    ));

    try {
      final userData = await AuthStorage.getUser();
      final userId = userData['user_id'] ?? '';

      // 3. Ambil halaman pertama menggunakan nilai filter yang BARU
      final transactions = await repository.fetchHistory(
        page: 1,
        userId: userId,
        searchQuery: newSearchQuery,
        transactionType: newTransactionType,
        status: newStatus,
      );

      // 4. Pancarkan state sukses dengan data baru dan reset halaman
      emit(state.copyWith(
        status: HistoryStatus.success,
        transactions: transactions,
        hasReachedMax: transactions.length < _postLimit,
        page: 2, // Halaman berikutnya adalah 2
      ));
    } catch (_) {
      emit(state.copyWith(status: HistoryStatus.failure));
    }
  }
}

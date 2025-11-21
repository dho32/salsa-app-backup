// bloc/po_search_bloc/po_search_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/task_maintenance/task_maintenance_event.dart';
import 'package:salsa/blocs/task_maintenance/task_maintenance_repository.dart';
import 'package:salsa/blocs/task_maintenance/task_maintenance_state.dart';

class TaskMaintenanceBloc extends Bloc<SearchPO, POSearchState> {
  final TaskMaintenanceRepository repository;

  TaskMaintenanceBloc({required this.repository}) : super(POSearchInitial()) {
    on<SearchPO>(_onSearchPO);
  }

  Future<void> _onSearchPO(SearchPO event, Emitter<POSearchState> emit) async {
    emit(POSearchLoading());
    try {
      final results = await repository.searchTransactions(
          event.transNo, event.maintenanceBy);
      emit(POSearchSuccess(results));
    } catch (e) {
      emit(POSearchFailure(e.toString()));
    }
  }
}

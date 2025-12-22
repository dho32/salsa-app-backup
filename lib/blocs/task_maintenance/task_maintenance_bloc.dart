import 'package:flutter_bloc/flutter_bloc.dart';
import 'task_maintenance_event.dart';
import 'task_maintenance_repository.dart';
import 'task_maintenance_state.dart';

class TaskMaintenanceBloc extends Bloc<TaskMaintenanceEvent, TaskMaintenanceState> {
  final TaskMaintenanceRepository repository;

  TaskMaintenanceBloc({required this.repository}) : super(POSearchInitial()) {
    on<SearchPO>(_onSearchPO);
    on<FetchPendingTasks>(_onFetchPendingTasks);
  }

  Future<void> _onSearchPO(SearchPO event, Emitter<TaskMaintenanceState> emit) async {
    emit(POSearchLoading());
    try {
      final results = await repository.searchTransactions(
          event.transNo, event.maintenanceBy);
      emit(POSearchSuccess(results));
    } catch (e) {
      emit(POSearchFailure(e.toString()));
    }
  }

  Future<void> _onFetchPendingTasks(FetchPendingTasks event, Emitter<TaskMaintenanceState> emit) async {
    emit(POSearchLoading());
    try {
      final results = await repository.getPendingTasks(
          event.maintenanceBy, event.createdBy);
      emit(TaskListLoaded(results));
    } catch (e) {
      emit(const TaskListLoaded([]));
      // print("Background fetch error: $e");
    }
  }
}
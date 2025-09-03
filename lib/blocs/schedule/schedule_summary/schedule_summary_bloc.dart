// lib/blocs/schedule_summary/schedule_summary_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:salsa/blocs/schedule/schedule_summary/schedule_summary_repository.dart';

part 'schedule_summary_event.dart';
part 'schedule_summary_state.dart';

class ScheduleSummaryBloc extends Bloc<ScheduleSummaryEvent, ScheduleSummaryState> {
  final ScheduleSummaryRepository repository;
  final String maintenanceBy;
  ScheduleSummaryBloc({required this.repository, required this.maintenanceBy}) : super(ScheduleSummaryInitial()) {
    on<FetchScheduleSummaryData>(_onFetchScheduleSummaryData);
  }

  Future<void> _onFetchScheduleSummaryData(
      FetchScheduleSummaryData event,
      Emitter<ScheduleSummaryState> emit,
      ) async {
    emit(ScheduleSummaryLoading());
    try {
      final loadedState = await repository.fetchSummaryData(maintenanceBy: maintenanceBy);
      emit(loadedState);
    } catch (e) {
      emit(ScheduleSummaryError(e.toString()));
    }
  }
}
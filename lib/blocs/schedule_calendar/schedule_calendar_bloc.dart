import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:salsa/blocs/schedule_calendar/schedule_calendar_repository.dart';

part 'schedule_calendar_event.dart';
part 'schedule_calendar_state.dart';

class ScheduleCalendarBloc extends Bloc<ScheduleCalendarEvent, ScheduleCalendarState> {
  final ScheduleCalendarRepository repository;

  ScheduleCalendarBloc({required this.repository}) : super(ScheduleCalendarInitial()) {
    on<FetchAllSchedules>(_onFetchAllSchedules);
    on<SelectCalendarDay>(_onSelectCalendarDay);
  }

  Future<void> _onFetchAllSchedules(
      FetchAllSchedules event,
      Emitter<ScheduleCalendarState> emit,
      ) async {
    emit(ScheduleCalendarLoading());
    try {
      final scheduleData = await repository.fetchAllSchedules();
      final today = DateTime.now();
      final initialPOList = await repository.fetchPoDetailsForDay(today);

      emit(ScheduleCalendarLoaded(
        scheduleData: scheduleData,
        selectedDay: today,
        selectedDayPOList: initialPOList,
      ));
    } catch (e) {
      emit(ScheduleCalendarError(e.toString()));
    }
  }

  Future<void> _onSelectCalendarDay(
      SelectCalendarDay event,
      Emitter<ScheduleCalendarState> emit,
      ) async {
    final currentState = state;
    if (currentState is ScheduleCalendarLoaded) {
      // Tampilkan loading di daftar PO saat data baru diambil
      emit(currentState.copyWith(
        selectedDay: event.day,
        isListLoading: true,
      ));

      final newPOList = await repository.fetchPoDetailsForDay(event.day);

      emit(currentState.copyWith(
        selectedDay: event.day,
        selectedDayPOList: newPOList,
      ));
    }
  }
}
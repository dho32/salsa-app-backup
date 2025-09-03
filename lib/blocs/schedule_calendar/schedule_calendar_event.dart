part of 'schedule_calendar_bloc.dart';

abstract class ScheduleCalendarEvent extends Equatable {
  const ScheduleCalendarEvent();
  @override
  List<Object> get props => [];
}

// Event untuk memuat semua data jadwal awal
class FetchAllSchedules extends ScheduleCalendarEvent {}

// Event saat pengguna memilih tanggal di kalender
class SelectCalendarDay extends ScheduleCalendarEvent {
  final DateTime day;
  const SelectCalendarDay(this.day);
  @override
  List<Object> get props => [day];
}
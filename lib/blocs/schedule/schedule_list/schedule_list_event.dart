// lib/blocs/schedule_list/schedule_list_event.dart

part of 'schedule_list_bloc.dart';

abstract class ScheduleListEvent extends Equatable {
  const ScheduleListEvent();

  @override
  List<Object> get props => [];
}

// Event untuk mengambil data dengan filter tertentu
class UpdateScheduleList extends ScheduleListEvent {
  final String status;
  final String keyword;
  final String maintenanceBy;

  const UpdateScheduleList(
      {
        required this.status,
        required this.keyword,
        required this.maintenanceBy,
      });

  @override
  List<Object> get props => [status, keyword, maintenanceBy];
}

class FetchScheduleList extends ScheduleListEvent {}

// lib/blocs/schedule_list/schedule_list_state.dart

part of 'schedule_list_bloc.dart';

// Enum untuk jenis filter
enum ScheduleListFilterType {
  overdue,
  today,
  scheduled,
  done,
  allPriority,
}

abstract class ScheduleListState extends Equatable {
  const ScheduleListState();

  @override
  List<Object> get props => [];
}

class ScheduleListInitial extends ScheduleListState {}

class ScheduleListLoading extends ScheduleListState {}

class ScheduleListError extends ScheduleListState {
  final String message;

  const ScheduleListError(this.message);

  @override
  List<Object> get props => [message];
}

class ScheduleListLoaded extends ScheduleListState {
  final List<ScheduleListItemModel> list;
  final bool hasMore;
  final int page;

  const ScheduleListLoaded({
    required this.list, required this.hasMore, required this.page,
  });

  @override
  List<Object> get props => [list, hasMore, page];
}

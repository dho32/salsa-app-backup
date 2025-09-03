// lib/blocs/schedule_summary/schedule_summary_event.dart

part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryEvent extends Equatable {
  const ScheduleSummaryEvent();
  @override
  List<Object> get props => [];
}

class FetchScheduleSummaryData extends ScheduleSummaryEvent {}
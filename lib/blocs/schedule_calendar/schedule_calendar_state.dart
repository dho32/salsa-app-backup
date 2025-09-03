part of 'schedule_calendar_bloc.dart';

class CalendarDayData {
  final DateTime date;
  final int posCount;
  final int scCount;

  const CalendarDayData({
    required this.date,
    required this.posCount,
    required this.scCount,
  });

  factory CalendarDayData.fromJson(Map<String, dynamic> json) {
    return CalendarDayData(
      date: DateTime.parse(json['date']),
      // DIUBAH: gunakan key baru dari JSON
      posCount: json['proof_of_service'],
      scCount: json['service_call'],
    );
  }
}

// Model untuk merepresentasikan satu jadwal (bisa PO atau Service Call)
class POService {
  final String transNo;
  final String description;
  final bool isDone;
  final String type; // 'POS' atau 'SC' untuk membedakan

  const POService({
    required this.transNo,
    required this.description,
    required this.isDone,
    required this.type,
  });

  factory POService.fromJson(Map<String, dynamic> json) {
    return POService(
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      isDone: json['is_done'] ?? false,
      type: json['type'] ?? 'UNKNOWN',
    );
  }
}

abstract class ScheduleCalendarState extends Equatable {
  const ScheduleCalendarState();

  @override
  List<Object?> get props => [];
}

class ScheduleCalendarInitial extends ScheduleCalendarState {}

class ScheduleCalendarLoading extends ScheduleCalendarState {}

class ScheduleCalendarError extends ScheduleCalendarState {
  final String message;

  const ScheduleCalendarError(this.message);

  @override
  List<Object?> get props => [message];
}

class ScheduleCalendarLoaded extends ScheduleCalendarState {
  final Map<DateTime, CalendarDayData> scheduleData;
  final DateTime selectedDay;
  final List<POService> selectedDayPOList;
  final bool isListLoading;

  const ScheduleCalendarLoaded({
    required this.scheduleData,
    required this.selectedDay,
    required this.selectedDayPOList,
    this.isListLoading = false,
  });

  ScheduleCalendarLoaded copyWith({
    DateTime? selectedDay,
    List<POService>? selectedDayPOList,
    bool? isListLoading,
  }) {
    return ScheduleCalendarLoaded(
      scheduleData: scheduleData,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedDayPOList: selectedDayPOList ?? this.selectedDayPOList,
      isListLoading: isListLoading ?? this.isListLoading,
    );
  }

  @override
  List<Object?> get props =>
      [scheduleData, selectedDay, selectedDayPOList, isListLoading];
}

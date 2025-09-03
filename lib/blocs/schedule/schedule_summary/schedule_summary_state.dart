// lib/blocs/schedule_summary/schedule_summary_state.dart

part of 'schedule_summary_bloc.dart';

// Model sederhana untuk daftar pekerjaan prioritas
class PriorityJob {
  final String transNo;
  final String type;
  final String customerName;
  final DateTime scheduleDate;
  final DateTime? validateDate; // Bisa jadi null
  final String status;
  final String note;

  const PriorityJob({
    required this.transNo,
    required this.type,
    required this.customerName,
    required this.scheduleDate,
    this.validateDate,
    required this.status,
    required this.note,
  });

  factory PriorityJob.fromJson(Map<String, dynamic> json) {
    // Helper untuk parse tanggal yang mungkin invalid
    DateTime? parseValidateDate(String dateStr) {
      if (dateStr == "1990-01-01") return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return PriorityJob(
      transNo: json['trans_no'] ?? 'N/A',
      type: json['type'] ?? '',
      customerName: json['customer_name'] ?? 'No Name',
      scheduleDate: DateTime.parse(json['schedule_date']),
      validateDate: parseValidateDate(json['validate_date']),
      status: json['status'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

// Model sederhana untuk data grafik bulanan
class MonthlyJobChartData {
  final String monthName;
  final String periode;
  final int posJobCount;
  final int roJobCount;
  final int rroJobCount;

  const MonthlyJobChartData({
    required this.monthName,
    required this.periode,
    required this.posJobCount,
    required this.roJobCount,
    required this.rroJobCount,
  });

  factory MonthlyJobChartData.fromJson(Map<String, dynamic> json) {
    return MonthlyJobChartData(
      monthName: json['month_name'] ?? '',
      periode: json['periode'] ?? '',
      posJobCount: json['pos_job_count'] ?? 0,
      roJobCount: json['ro_job_count'] ?? 0,
      rroJobCount: json['rro_job_count'] ?? 0,
    );
  }
}

abstract class ScheduleSummaryState extends Equatable {
  const ScheduleSummaryState();
  @override
  List<Object> get props => [];
}

class ScheduleSummaryInitial extends ScheduleSummaryState {}
class ScheduleSummaryLoading extends ScheduleSummaryState {}
class ScheduleSummaryError extends ScheduleSummaryState {
  final String message;
  const ScheduleSummaryError(this.message);
  @override
  List<Object> get props => [message];
}

class ScheduleSummaryLoaded extends ScheduleSummaryState {
  final int jobsDoneCount;
  final int jobsScheduledCount;
  final int jobsOverdueCount;
  final int jobsTodayCount;
  final List<PriorityJob> priorityJobs;
  final List<MonthlyJobChartData> monthlyChartData;

  const ScheduleSummaryLoaded({
    required this.jobsDoneCount,
    required this.jobsScheduledCount,
    required this.jobsOverdueCount,
    required this.jobsTodayCount,
    required this.priorityJobs,
    required this.monthlyChartData,
  });

  @override
  List<Object> get props => [
    jobsDoneCount,
    jobsScheduledCount,
    jobsOverdueCount,
    jobsTodayCount,
    priorityJobs,
    monthlyChartData,
  ];
}
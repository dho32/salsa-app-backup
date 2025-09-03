class ServiceCallSummaryModel {
  final String period;
  final int total;
  final int done;
  final int notDone;
  final int notDonePriority;
  final List<TopIssue> topIssues;
  final Map<String, int> weeklyPerformance;

  ServiceCallSummaryModel({
    required this.period,
    required this.total,
    required this.done,
    required this.notDone,
    required this.notDonePriority,
    required this.topIssues,
    required this.weeklyPerformance,
  });

  factory ServiceCallSummaryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCallSummaryModel(
      period: json['period'],
      total: json['total_service_call'],
      done: json['done'],
      notDone: json['not_done'],
      notDonePriority: json['not_done_priority'],
      topIssues: (json['top_issues'] as List)
          .map((e) => TopIssue.fromJson(e))
          .toList(),
      weeklyPerformance: Map<String, int>.from(json['weekly_performance']),
    );
  }
}

class TopIssue {
  final String issue;
  final int count;

  TopIssue({required this.issue, required this.count});

  factory TopIssue.fromJson(Map<String, dynamic> json) {
    return TopIssue(
      issue: json['issue'],
      count: json['count'],
    );
  }
}

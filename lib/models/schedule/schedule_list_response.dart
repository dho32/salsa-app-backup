import 'package:salsa/models/schedule/schedule_list_model.dart';

class ScheduleListResponse {
  final List<ScheduleListItemModel> list;
  final bool hasMore;

  ScheduleListResponse({
    required this.list,
    required this.hasMore,
  });

  factory ScheduleListResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleListResponse(
      list: (json['list'] as List<dynamic>? ?? [])
          .map((e) => ScheduleListItemModel.fromJson(e))
          .toList(),
      hasMore: json['has_more'] ?? false,
    );
  }
}

import 'service_call_list_model.dart';

class ServiceCallListResponse {
  final List<ServiceCallListModel> list;
  final bool hasMore;

  ServiceCallListResponse({
    required this.list,
    required this.hasMore,
  });

  factory ServiceCallListResponse.fromJson(Map<String, dynamic> json) {
    return ServiceCallListResponse(
      list: (json['list'] as List<dynamic>? ?? [])
          .map((e) => ServiceCallListModel.fromJson(e))
          .toList(),
      hasMore: json['has_more'] ?? false,
    );
  }
}

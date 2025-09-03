abstract class ServiceCallListEvent {}

class UpdateServiceCallFilter extends ServiceCallListEvent {
  final String status;
  final String keyword;
  final String maintenanceBy;

  UpdateServiceCallFilter({
    required this.status,
    required this.keyword,
    required this.maintenanceBy,
  });
}

class FetchServiceCallList extends ServiceCallListEvent {}

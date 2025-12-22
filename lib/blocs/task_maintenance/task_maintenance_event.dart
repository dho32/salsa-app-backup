abstract class TaskMaintenanceEvent {}

class SearchPO extends TaskMaintenanceEvent {
  final String transNo;
  final String maintenanceBy;
  SearchPO(this.transNo, this.maintenanceBy);
}

class FetchPendingTasks extends TaskMaintenanceEvent {
  final String maintenanceBy;
  final String createdBy;
  FetchPendingTasks(this.maintenanceBy, this.createdBy);
}
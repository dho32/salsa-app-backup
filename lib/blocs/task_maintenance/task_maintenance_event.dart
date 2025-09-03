abstract class POSearchEvent {}

enum MaintenanceType {
  service, // Untuk layanan service
  cuci,    // Untuk layanan cuci
}

class SearchPO extends POSearchEvent {
  final String transNo;
  final String maintenanceBy;
  final MaintenanceType taskType;
  SearchPO(this.transNo, this.maintenanceBy, this.taskType);
}
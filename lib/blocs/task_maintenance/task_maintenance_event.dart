abstract class POSearchEvent {}

class SearchPO extends POSearchEvent {
  final String transNo;
  final String maintenanceBy;
  SearchPO(this.transNo, this.maintenanceBy);
}
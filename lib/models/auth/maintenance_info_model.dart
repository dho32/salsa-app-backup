class MaintenanceInfo {
  final String maintenanceBy;
  final String maintenanceByName;

  MaintenanceInfo({required this.maintenanceBy, required this.maintenanceByName});

  factory MaintenanceInfo.fromJson(Map<String, dynamic> json) {
    return MaintenanceInfo(
      maintenanceBy: json['maintenance_by'] ?? '',
      maintenanceByName: json['maintenance_by_name'] ?? '',
    );
  }
}
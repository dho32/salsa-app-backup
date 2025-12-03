class MaintenanceInfo {
  final String maintenanceType;
  final String maintenanceBy;
  final String maintenanceByName;

  MaintenanceInfo({required this.maintenanceType, required this.maintenanceBy, required this.maintenanceByName});

  factory MaintenanceInfo.fromJson(Map<String, dynamic> json) {
    return MaintenanceInfo(
      maintenanceType: json['maintenance_type'] ?? 'WH',
      maintenanceBy: json['maintenance_by'] ?? '',
      maintenanceByName: json['maintenance_by_name'] ?? '',
    );
  }
}
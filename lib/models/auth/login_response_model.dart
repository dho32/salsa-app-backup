// Model untuk menampung data warehouse
class Warehouse {
  final String id;
  final String name;

  Warehouse({required this.id, required this.name});

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['warehouse_id'] ?? '',
      name: json['warehouse_name'] ?? '',
    );
  }
}

// Model untuk menampung hasil dari API login
class LoginResponse {
  final String userType; // "vendor" atau "maintenance"
  final String? token; // Akan null jika userType = "maintenance"
  final List<Warehouse> warehouses; // Akan kosong jika userType = "vendor"

  LoginResponse({
    required this.userType,
    this.token,
    this.warehouses = const [],
  });
}
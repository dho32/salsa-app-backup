import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/dashboard/dashboard_data_model.dart';
import '../../models/dashboard/dashboard_response_model.dart';
import '../auth/auth_storage.dart'; // penting!
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

class DashboardRepository {
  final http.Client client;
  final AuthBloc authBloc;

  DashboardRepository({http.Client? client, required this.authBloc})
      : client = client ?? http.Client();

  Future<DashboardDataModel> fetchDashboardData() async {
    // 🔐 Cek token expired
    final isExpired = await AuthStorage.isTokenExpired();
    if (isExpired) {
      authBloc.add(LoggedOut()); // trigger auto logout
      throw Exception("Sesi kamu telah berakhir. Silakan login kembali.");
    }

    // ✅ Ambil token dari storage
    final token = await AuthStorage.getToken();

    final response = await client.get(
      Uri.parse('https://ujaxnyipj6.execute-api.ap-southeast-1.amazonaws.com/sandbox/service_call/list?maintenance_by=V000065&status=done&page=0'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final dashboardResponse = DashboardResponseModel.fromJson(data);

      if (dashboardResponse.status == 'OK' &&
          dashboardResponse.result != null) {
        return dashboardResponse.result!;
      } else {
        throw Exception(dashboardResponse.message);
      }
    } else {
      throw Exception("Gagal memuat data dashboard");
    }
  }
}

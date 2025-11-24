import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/history/history_transaction_model.dart';

class HistoryRepository {
  Future<List<HistoryTransactionModel>> fetchHistory({
    required String userId,
    int page = 1,
    String searchQuery = '',
    String transactionType = 'ALL',
    String status = 'ALL',
  }) async {
    final params = {
      'user_id': userId,
      'page': page.toString(),
      'search': searchQuery,
      'trans_type': transactionType,
      'status': status,
    };

    Uri uri = getUrl(pathUrl: '/history/list', params: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        final List<dynamic> results = body['result'] ?? [];
        return results
            .map((json) => HistoryTransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception('API returned error: ${body['message']}');
      }
    } else {
      throw Exception('Failed to load history: ${response.statusCode}');
    }
  }
}

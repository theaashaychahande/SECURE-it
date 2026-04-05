import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://secure-it-production.up.railway.app";

  /// Evaluates risk for a given set of transaction features.
  /// Features must follow the backend schema precisely.
  Future<Map<String, dynamic>> evaluateRisk({
    required double amount,
    required bool isNewPayee,
    required int hourOfDay,
    required double deviceTrustScore,
  }) async {
    final url = Uri.parse("$baseUrl/evaluate-risk");

    // Creating request payload according to Pydantic TransactionData model
    final Map<String, dynamic> body = {
      "amount": amount,
      "is_new_payee": isNewPayee ? 1 : 0,
      "time_of_day_hour": hourOfDay,
      "device_trust_score": deviceTrustScore,
      // Defaulting others for now, but these can be expanded
      "ip_risk_score": 0.0,
      "txn_count_1h": 1,
      "txn_count_24h": 1,
      "failed_txn_24h": 0,
      "geo_distance": 0.0,
      "amount_deviation": 0.0,
      "is_international": 0,
      "payment_channel_code": 0,
      "merchant_risk_score": 0.0,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to evaluate risk. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  /// Health check to verify Railway deployment responsiveness.
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/health"));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

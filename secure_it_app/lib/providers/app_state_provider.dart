import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isProtected = true;
  String _trustedContactName = '';
  String _trustedContactNumber = '';
  String _language = 'English';
  
  // Risk state
  bool _isLoading = false;
  Map<String, dynamic>? _lastRiskResult;

  bool get isProtected => _isProtected;
  String get trustedContactName => _trustedContactName;
  String get trustedContactNumber => _trustedContactNumber;
  String get language => _language;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get lastRiskResult => _lastRiskResult;

  bool get hasTrustedContact => _trustedContactName.isNotEmpty && _trustedContactNumber.isNotEmpty;

  void toggleProtection() {
    _isProtected = !_isProtected;
    notifyListeners();
  }

  Future<void> evaluateTransactionRisk({
    required double amount,
    required bool isNewPayee,
    required int hourOfDay,
  }) async {
    _isLoading = true;
    _lastRiskResult = null;
    notifyListeners();

    try {
      _lastRiskResult = await _apiService.evaluateRisk(
        amount: amount,
        isNewPayee: isNewPayee,
        hourOfDay: hourOfDay,
        deviceTrustScore: 0.85, // Mock score for now
      );
    } catch (e) {
      debugPrint("Error evaluating risk: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTrustedContact(String name, String number) {
    _trustedContactName = name;
    _trustedContactNumber = number;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }
}

import 'dart:async';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../providers/api_service.dart';

class AutomationService {
  static final AutomationService _instance = AutomationService._internal();
  factory AutomationService() => _instance;
  AutomationService._internal();

  StreamSubscription<AccessibilityEvent>? _subscription;
  bool _isOverlayOpen = false;

  // Track the last processed transaction to avoid double-alerts
  String? _lastUpiId;
  String? _lastAmount;

  void startMonitoring() {
    _subscription = FlutterAccessibilityService.accessStream.listen((event) async {
      final packageName = event.packageName ?? "";
      
      // Target Indian UPI Apps
      final targetApps = [
        "com.google.android.apps.nbu.paisa.user", // GPay
        "com.phonepe.app",                        // PhonePe
        "com.paytm.business",                     // Paytm (and variants)
        "net.one97.paytm",
      ];

      if (targetApps.contains(packageName)) {
        _handlePaymentScreen(event);
      }
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
  }

  void _handlePaymentScreen(AccessibilityEvent event) async {
    final nodes = event.nodes ?? [];
    String? upiId;
    String? amount;

    for (var node in nodes) {
      final text = node.text ?? "";
      
      // 1. Extract UPI ID (Pattern: contains '@')
      if (text.contains('@') && text.length > 5 && !text.contains(' ')) {
        upiId = text.trim();
      }

      // 2. Extract Amount (Pattern: numeric value after ₹ or "Pay")
      // This is a heuristic - looks for numbers in nodes that might be amounts
      final amountRegex = RegExp(r'(?:₹|Rs\.?|Pay)\s*([\d,]+(?:\.\d{2})?)');
      final match = amountRegex.firstMatch(text);
      if (match != null) {
        amount = match.group(1)?.replaceAll(',', '');
      } else if (RegExp(r'^\d+(\.\d{2})?$').hasMatch(text) && text.length < 10) {
        // Fallback for standalone numbers that look like amounts
        amount = text;
      }
    }

    if (upiId != null && amount != null) {
      if (upiId == _lastUpiId && amount == _lastAmount) return;
      
      _lastUpiId = upiId;
      _lastAmount = amount;
      final parsedAmount = double.tryParse(amount) ?? 0;

      print("🚨 DATA EXTRACTED: UPI: $upiId, Amount: $amount");
      
      // Evaluate Risk using existing ApiService
      final apiService = ApiService();
      try {
        final riskResult = await apiService.evaluateRisk(
          amount: parsedAmount,
          isNewPayee: true, // Automations usually encounter new payees in scams
          hourOfDay: DateTime.now().hour,
          deviceTrustScore: 0.85, 
        );

        // Show Overlay if High Risk (> 70)
        if (riskResult['risk_score'] > 70 && !_isOverlayOpen) {
          _showScamOverlay(upiId, amount, riskResult['risk_score']);
        }
      } catch (e) {
        print("Error in background risk check: $e");
      }
    }
  }

  void _showScamOverlay(String upiId, String amount, int score) async {
    _isOverlayOpen = true;
    
    if (await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.right,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );
      
      // Share data with the overlay via platform channel or local storage
      // In this version, the overlay will fetch current state from the service
    }
  }
}

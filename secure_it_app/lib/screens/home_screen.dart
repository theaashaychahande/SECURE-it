import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/warning_overlay_card.dart';

import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isAccessibilityEnabled = false;
  bool _isOverlayEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final access = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = access;
        _isOverlayEnabled = overlay;
      });
    }
  }

  void _showWarning(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => WarningOverlayCard(
        riskScore: (result['risk_score'] * 100).toInt(),
        title: '${result['risk_level']} Risk Detected!',
        description: 'AI detected suspicious patterns. ${result['risk_score'] > 0.8 ? "Highly likely to be a scam." : "Caution recommended."}',
        onCancel: () => Navigator.of(context).pop(),
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed('/education');
        },
      ),
    );
  }

  Future<void> _handleScan(BuildContext context, AppStateProvider state) async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    await state.evaluateTransactionRisk(
      amount: amount,
      isNewPayee: true, // For simulation
      hourOfDay: DateTime.now().hour,
    );

    if (!mounted) return;

    if (state.lastRiskResult != null && state.lastRiskResult!['is_high_risk'] == true) {
      _showWarning(context, state.lastRiskResult!);
    } else if (state.lastRiskResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction Safe. No high risk detected.'),
          backgroundColor: AppTheme.accentTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SECURE-it', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Security Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.amber),
                        const SizedBox(width: 12),
                        Text(
                          "AUTO-DEFENSE ENGINE",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.amber, letterSpacing: 1.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PermissionItem(
                      label: "Accessibility Monitor",
                      status: _isAccessibilityEnabled,
                      onTap: () async {
                        await FlutterAccessibilityService.requestAccessibilityPermission();
                        _checkPermissions();
                      },
                    ),
                    const SizedBox(height: 12),
                    _PermissionItem(
                      label: "System Warning Overlay",
                      status: _isOverlayEnabled,
                      onTap: () async {
                        await FlutterOverlayWindow.requestPermission();
                        _checkPermissions();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: state.isProtected ? value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isProtected 
                          ? AppTheme.accentTeal.withOpacity(0.2) 
                          : AppTheme.errorRed.withOpacity(0.2),
                        boxShadow: state.isProtected ? [
                          BoxShadow(
                            color: AppTheme.accentTeal.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ] : [],
                      ),
                      child: Icon(
                        state.isProtected ? Icons.shield : Icons.shield_outlined,
                        size: 80,
                        color: state.isProtected ? AppTheme.accentTeal : AppTheme.errorRed,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                state.isProtected ? 'You are Protected' : 'Protection Disabled',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: state.isProtected ? AppTheme.accentTeal : AppTheme.errorRed,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Transaction Amount (₹)',
                  hintText: 'Enter amount to scan',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : () => _handleScan(context, state),
                  icon: state.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.document_scanner),
                  label: Text(state.isLoading ? 'Analyzing...' : 'Scan Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isProtected ? AppTheme.accentTeal : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final String label;
  final bool status;
  final VoidCallback onTap;

  const _PermissionItem({
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status ? AppTheme.accentTeal.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: status ? AppTheme.accentTeal.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                ),
              ),
              child: Text(
                status ? "ACTIVE" : "SETUP",
                style: TextStyle(
                  color: status ? AppTheme.accentTeal : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

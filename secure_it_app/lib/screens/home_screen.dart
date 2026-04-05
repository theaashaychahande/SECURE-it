import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/warning_overlay_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _amountController = TextEditingController();

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
              const SizedBox(height: 40),
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

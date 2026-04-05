import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:url_launcher/url_launcher.dart';

class ScamOverlayWidget extends StatefulWidget {
  const ScamOverlayWidget({super.key});

  @override
  State<ScamOverlayWidget> createState() => _ScamOverlayWidgetState();
}

class _ScamOverlayWidgetState extends State<ScamOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C1E),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                "⚠️ CRITICAL ALERT",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This UPI transaction was automatically scanned and identified as a HIGH-RISK scam attempt. Are you being forced to pay for a lottery, electricity bill, or KYC update?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              _ActionButton(
                icon: Icons.phone_in_talk,
                label: "CALL TRUSTED MEMBER",
                color: Colors.blueAccent,
                onTap: () async {
                  // This would ideally fetch from a local storage to avoid complex state here
                  final Uri launchUri = Uri(scheme: 'tel', path: '9000000000');
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                },
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.security,
                label: "MARK AS SCAM (DEMO REPORT)",
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mock Report sent to cybercrime portal (1930)")),
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    FlutterOverlayWindow.closeOverlay();
                  });
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => FlutterOverlayWindow.closeOverlay(),
                child: const Text(
                  "I'LL TAKE THE RISK (DISMISS)",
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

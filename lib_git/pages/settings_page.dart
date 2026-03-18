import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final String status;
  final String rawLine;
  final String selectedAddress;

  const SettingsPage({
    super.key,
    required this.status,
    required this.rawLine,
    required this.selectedAddress,
  });

  @override
  Widget build(BuildContext context) {
    Widget card(String title, String body) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1A24),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  color: Color(0xFFE8E1F8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 8),
            Text(
              body.isEmpty ? '-' : body,
              style: const TextStyle(color: Color(0xFFBFB7CF)),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFFE8E1F8),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 20),
            card('Status', status),
            card('Selected address', selectedAddress),
            card('Raw data', rawLine),
          ],
        ),
      ),
    );
  }
}
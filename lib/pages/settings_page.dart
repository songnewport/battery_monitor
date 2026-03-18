import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';

class SettingsPage extends StatelessWidget {
  final String status;
  final String selectedAddress;
  final String rawLine;

  const SettingsPage({
    super.key,
    required this.status,
    required this.selectedAddress,
    required this.rawLine,
  });

  Widget _infoCard(String title, String body, IconData icon) {
    return AppCard(
      color: AppColors.panelAlt,
      border: const Border.fromBorderSide(
        BorderSide(color: AppColors.panelBorder, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: AppTextStyles.cardLabel),
                const SizedBox(height: 8),
                Text(body.isEmpty ? '-' : body, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diagnostics', style: AppTextStyles.pageTitle),
            const SizedBox(height: AppSpacing.titleToSection),
            _infoCard('Status', status, Icons.sensors),
            const SizedBox(height: AppSpacing.cardGap),
            _infoCard('Selected address', selectedAddress, Icons.memory),
            const SizedBox(height: AppSpacing.cardGap),
            _infoCard('Raw data', rawLine, Icons.code),
          ],
        ),
      ),
    );
  }
}

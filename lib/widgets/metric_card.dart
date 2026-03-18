import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppColors.icon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label.toUpperCase(), style: AppTextStyles.cardLabel),
          ),
          Text(value, style: AppTextStyles.cardValue),
          const SizedBox(width: 6),
          Text(unit, style: AppTextStyles.unit),
        ],
      ),
    );
  }
}

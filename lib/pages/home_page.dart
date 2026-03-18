import 'package:flutter/material.dart';
import '../models/battery_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/sparkline_card.dart';
import '../widgets/status_chip.dart';

class HomePage extends StatelessWidget {
  final BatteryData data;
  final String status;
  final String selectedAddress;
  final List<double> voltageHistory;
  final List<double> currentHistory;
  final bool connected;

  const HomePage({
    super.key,
    required this.data,
    required this.status,
    required this.selectedAddress,
    required this.voltageHistory,
    required this.currentHistory,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Battery Monitor', style: AppTextStyles.pageTitle),
                ),
                StatusChip(
                  connected: connected,
                  label: connected ? 'LIVE' : 'OFFLINE',
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppCard(
              color: AppColors.panelAlt,
              border: const Border.fromBorderSide(
                BorderSide(color: AppColors.panelBorder, width: 1.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VEHICLE LINK', style: AppTextStyles.cardLabel),
                  const SizedBox(height: 10),
                  Text(
                    connected ? 'Connected and listening' : 'Disconnected',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(selectedAddress, style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            MetricCard(
              icon: Icons.battery_5_bar,
              label: 'Voltage',
              value: data.voltage.toStringAsFixed(2),
              unit: 'V',
            ),
            const SizedBox(height: AppSpacing.cardGap),
            MetricCard(
              icon: Icons.flash_on,
              label: 'Current',
              value: data.current.toStringAsFixed(1),
              unit: 'A',
            ),
            const SizedBox(height: AppSpacing.cardGap),
            MetricCard(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: data.temperature.toStringAsFixed(1),
              unit: '°C',
            ),
            const SizedBox(height: AppSpacing.cardGap),
            MetricCard(
              icon: Icons.bolt,
              label: 'Power',
              value: data.power.toStringAsFixed(1),
              unit: 'W',
            ),
            const SizedBox(height: AppSpacing.cardGap),
            SparklineCard(
              title: 'Voltage Trend',
              subtitle: 'Recent live samples',
              values: voltageHistory,
              rightValue: '${data.voltage.toStringAsFixed(2)} V',
            ),
            const SizedBox(height: AppSpacing.cardGap),
            SparklineCard(
              title: 'Current Trend',
              subtitle: 'Recent live samples',
              values: currentHistory,
              rightValue: '${data.current.toStringAsFixed(1)} A',
            ),
          ],
        ),
      ),
    );
  }
}

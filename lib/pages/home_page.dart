import 'package:flutter/material.dart';
import '../models/battery_data.dart';
import '../widgets/metric_card.dart';


class HomePage extends StatelessWidget {
  final BatteryData data;
  final String status;
  final String selectedAddress;


  const HomePage({
    super.key,
    required this.data,
    required this.status,
    required this.selectedAddress,
  });


  @override
  Widget build(BuildContext context) {
    final bool connected = status.toLowerCase().contains('connected');


    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Battery Monitor',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFE8E1F8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1A24),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: connected
                      ? const Color(0xFFB8A8FF)
                      : const Color(0xFF3A3446),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: connected
                        ? const Color(0xFFE8E1F8)
                        : const Color(0xFFBFB7CF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connected ? 'Connected' : 'Disconnected',
                          style: const TextStyle(
                            color: Color(0xFFE8E1F8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedAddress,
                          style: const TextStyle(
                            color: Color(0xFFBFB7CF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            MetricCard(
              title: 'Voltage',
              value: data.voltage.toStringAsFixed(2),
              unit: 'V',
              icon: Icons.battery_5_bar,
            ),
            MetricCard(
              title: 'Current',
              value: data.current.toStringAsFixed(1),
              unit: 'A',
              icon: Icons.flash_on,
            ),
            MetricCard(
              title: 'Temperature',
              value: data.temperature.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
            ),
            MetricCard(
              title: 'Power',
              value: data.power.toStringAsFixed(1),
              unit: 'W',
              icon: Icons.bolt,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';

class DevicesPage extends StatelessWidget {
  final List<ScanResult> results;
  final String selectedAddress;
  final String status;
  final Future<void> Function() onScan;
  final Future<void> Function() onDisconnect;
  final Future<void> Function(String address) onConnect;
  final ValueChanged<String> onSelectAddress;
  final bool connected;

  const DevicesPage({
    super.key,
    required this.results,
    required this.selectedAddress,
    required this.status,
    required this.onScan,
    required this.onDisconnect,
    required this.onConnect,
    required this.onSelectAddress,
    required this.connected,
  });

  String _displayName(ScanResult r) {
    final advName = r.advertisementData.advName.trim();
    final devName = r.device.platformName.trim();

    if (advName.isNotEmpty) return advName;
    if (devName.isNotEmpty) return devName;
    return 'Unknown device';
  }

  List<ScanResult> _sortedResults() {
    final list = List<ScanResult>.from(results);

    int score(ScanResult r) {
      final name = _displayName(r).toUpperCase();
      final address = r.device.remoteId.str.toUpperCase();
      final selected = address == selectedAddress.toUpperCase();

      if (selected) return 0;
      if (name.contains('GSL') || name.contains('EBYTE') || name.contains('BT5005')) {
        return 1;
      }
      if (name != 'UNKNOWN DEVICE') return 2;
      return 3;
    }

    list.sort((a, b) {
      final s1 = score(a);
      final s2 = score(b);
      if (s1 != s2) return s1.compareTo(s2);
      if (a.rssi != b.rssi) return b.rssi.compareTo(a.rssi);
      return a.device.remoteId.str.compareTo(b.device.remoteId.str);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedResults();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('BLE Devices', style: AppTextStyles.pageTitle),
                ),
                StatusChip(
                  connected: connected,
                  label: connected ? 'CONNECTED' : 'READY',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.titleToSection),
            AppCard(
              color: AppColors.panelAlt,
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Scan',
                      onPressed: onScan,
                      icon: Icons.radar,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.buttonGap),
                  Expanded(
                    child: AppButton(
                      label: 'Disconnect',
                      onPressed: onDisconnect,
                      icon: Icons.link_off,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            Expanded(
              child: sorted.isEmpty
                  ? const Center(
                child: Text('No devices yet. Tap Scan.', style: AppTextStyles.body),
              )
                  : ListView.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.cardGap),
                itemBuilder: (context, index) {
                  final r = sorted[index];
                  final address = r.device.remoteId.str;
                  final name = _displayName(r);
                  final selected = address == selectedAddress;
                  final thisIsConnected = connected && selected;

                  return AppCard(
                    color: selected ? AppColors.panelAlt : AppColors.panel,
                    border: selected
                        ? const Border.fromBorderSide(
                      BorderSide(color: AppColors.panelBorder, width: 1.2),
                    )
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            name == 'Unknown device'
                                ? Icons.bluetooth_searching
                                : Icons.bluetooth_audio,
                            color: AppColors.icon,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyles.sectionTitle),
                              const SizedBox(height: 4),
                              Text(address, style: AppTextStyles.body),
                              const SizedBox(height: 4),
                              Text('RSSI ${r.rssi} dBm', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 126,
                          child: AppButton(
                            label: thisIsConnected ? 'Connected' : 'Connect',
                            onPressed: thisIsConnected
                                ? null
                                : () async {
                              onSelectAddress(address);
                              await onConnect(address);
                            },
                            filled: thisIsConnected,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


class DevicesPage extends StatelessWidget {
  final List<ScanResult> results;
  final String selectedAddress;
  final String status;
  final Future<void> Function() onScan;
  final Future<void> Function(String address) onConnect;
  final Future<void> Function() onDisconnect;
  final ValueChanged<String> onSelectAddress;


  const DevicesPage({
    super.key,
    required this.results,
    required this.selectedAddress,
    required this.status,
    required this.onScan,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSelectAddress,
  });


  List<ScanResult> _sortedResults() {
    final list = List<ScanResult>.from(results);


    int score(ScanResult r) {
      final name = r.device.platformName.trim().toUpperCase();
      final address = r.device.remoteId.str.toUpperCase();
      final selected = address == selectedAddress.toUpperCase();


      if (selected) return 0;
      if (name.contains('DSD')) return 1;
      if (name.isNotEmpty) return 2;
      return 3;
    }


    list.sort((a, b) {
      final s1 = score(a);
      final s2 = score(b);
      if (s1 != s2) return s1.compareTo(s2);


      if (a.rssi != b.rssi) {
        return b.rssi.compareTo(a.rssi);
      }


      return a.device.remoteId.str.compareTo(b.device.remoteId.str);
    });


    return list;
  }


  @override
  Widget build(BuildContext context) {
    final sorted = _sortedResults();
    final bool connected = status.toLowerCase().contains('connected');


    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BLE Devices',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFE8E1F8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onScan,
                  child: const Text('Scan'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onDisconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sorted.isEmpty
                  ? const Center(
                child: Text(
                  'No devices yet. Tap Scan.',
                  style: TextStyle(color: Color(0xFFBFB7CF)),
                ),
              )
                  : ListView.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final r = sorted[index];
                  final address = r.device.remoteId.str;
                  final name = r.device.platformName.trim().isNotEmpty
                      ? r.device.platformName.trim()
                      : 'Unknown device';


                  final selected = address == selectedAddress;
                  final thisIsConnected = connected && selected;


                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1A24),
                      borderRadius: BorderRadius.circular(18),
                      border: selected
                          ? Border.all(
                        color: const Color(0xFFE8E1F8),
                        width: 1.4,
                      )
                          : null,
                    ),
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFE8E1F8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '$address\nRSSI ${r.rssi} dBm',
                        style: const TextStyle(
                          color: Color(0xFFBFB7CF),
                          fontSize: 14,
                        ),
                      ),
                      isThreeLine: true,
                      onTap: () => onSelectAddress(address),
                      trailing: ElevatedButton(
                        onPressed: thisIsConnected
                            ? null
                            : () async {
                          onSelectAddress(address);
                          await onConnect(address);
                        },
                        child: Text(
                          thisIsConnected ? 'Connected' : 'Connect',
                        ),
                      ),
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
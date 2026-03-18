import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/battery_data.dart';
import '../services/ble_service.dart';
import 'home_page.dart';
import 'devices_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final BleService ble = BleService();

  int index = 0;
  BatteryData currentData = BatteryData.empty;
  String status = 'Disconnected';
  String rawLine = '';
  List<ScanResult> results = [];

  final List<double> _voltageHistory = [];
  final List<double> _currentHistory = [];

  StreamSubscription<BatteryData>? _dataSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<String>? _rawSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  void _pushHistory(List<double> list, double value, {int max = 24}) {
    list.add(value);
    if (list.length > max) list.removeAt(0);
  }

  @override
  void initState() {
    super.initState();

    _dataSub = ble.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          currentData = data;
          _pushHistory(_voltageHistory, data.voltage);
          _pushHistory(_currentHistory, data.current);
        });
      }
    });

    _statusSub = ble.statusStream.listen((value) {
      if (mounted) setState(() => status = value);
    });

    _rawSub = ble.rawStream.listen((value) {
      if (mounted) setState(() => rawLine = value);
    });

    _scanSub = ble.scanResultsStream.listen((value) {
      if (mounted) setState(() => results = value);
    });

    Future.microtask(() async {
      await ble.initialize();
      await ble.connectAuto();
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _statusSub?.cancel();
    _rawSub?.cancel();
    _scanSub?.cancel();
    ble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        data: currentData,
        status: status,
        selectedAddress: ble.selectedAddress,
        connected: ble.isConnected,
        voltageHistory: _voltageHistory.isEmpty ? [0, 0, 0] : _voltageHistory,
        currentHistory: _currentHistory.isEmpty ? [0, 0, 0] : _currentHistory,
      ),
      DevicesPage(
        results: results,
        selectedAddress: ble.selectedAddress,
        status: status,
        connected: ble.isConnected,
        onScan: ble.startScan,
        onDisconnect: ble.disconnect,
        onConnect: ble.connectByAddress,
        onSelectAddress: (address) {
          ble.setSelectedAddress(address);
          setState(() {});
        },
      ),
      SettingsPage(
        status: status,
        selectedAddress: ble.selectedAddress,
        rawLine: rawLine,
      ),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Drive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_searching_rounded),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: 'Diag',
          ),
        ],
      ),
    );
  }
}

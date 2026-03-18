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


  StreamSubscription<BatteryData>? _dataSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<String>? _rawSub;
  StreamSubscription<List<ScanResult>>? _scanSub;


  @override
  void initState() {
    super.initState();


    ble.initialize();


    _dataSub = ble.dataStream.listen((data) {
      if (mounted) {
        setState(() => currentData = data);
      }
    });


    _statusSub = ble.statusStream.listen((value) {
      if (mounted) {
        setState(() => status = value);
      }
    });


    _rawSub = ble.rawStream.listen((value) {
      if (mounted) {
        setState(() => rawLine = value);
      }
    });


    _scanSub = ble.scanResultsStream.listen((value) {
      if (mounted) {
        setState(() => results = value);
      }
    });


    Future.microtask(() => ble.connectAuto());
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
      ),
      DevicesPage(
        results: results,
        selectedAddress: ble.selectedAddress,
        status: status,
        onScan: ble.startScan,
        onConnect: ble.connectByAddress,
        onDisconnect: ble.disconnect,
        onSelectAddress: (address) {
          ble.setSelectedAddress(address);
          setState(() {});
        },
      ),
      SettingsPage(
        status: status,
        rawLine: rawLine,
        selectedAddress: ble.selectedAddress,
      ),
    ];


    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
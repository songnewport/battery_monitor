import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';

Future<void> _requestStartupPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestStartupPermissions();

  // ⚠️ 这里必须是 BatteryMonitorApp
  runApp(const BatteryMonitorApp());
}
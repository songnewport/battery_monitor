import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/battery_data.dart';

class BleService {
  static final Guid serviceUuid =
  Guid('0000FFE0-0000-1000-8000-00805F9B34FB');
  static final Guid characteristicUuid =
  Guid('0000FFE1-0000-1000-8000-00805F9B34FB');

  final StreamController<BatteryData> _dataController =
  StreamController<BatteryData>.broadcast();
  final StreamController<String> _statusController =
  StreamController<String>.broadcast();
  final StreamController<String> _rawController =
  StreamController<String>.broadcast();
  final StreamController<List<ScanResult>> _scanResultsController =
  StreamController<List<ScanResult>>.broadcast();

  Stream<BatteryData> get dataStream => _dataController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get rawStream => _rawController.stream;
  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  String _buffer = '';
  String _lastRawLine = '';
  BatteryData _currentData = BatteryData.empty;
  String _selectedAddress = '68:5E:1C:2B:64:44';

  String get selectedAddress => _selectedAddress;
  String get lastRawLine => _lastRawLine;
  BluetoothDevice? get device => _device;

  Future<void> initialize() async {
    _statusController.add('Disconnected');

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      _scanResultsController.add(results);
    });
  }

  void setSelectedAddress(String address) {
    _selectedAddress = address.trim();
    _statusController.add('Selected: $_selectedAddress');
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _statusController.add('Scanning...');

    await FlutterBluePlus.stopScan();
    await Future.delayed(const Duration(milliseconds: 400));
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _statusController.add('Scan stopped');
  }

  Future<void> connectAuto() async {
    await connectByAddress(_selectedAddress);
  }

  Future<void> connectByAddress(String address) async {
    _selectedAddress = address.trim();
    _statusController.add('Connecting...');

    try {
      await disconnect();

      final target = BluetoothDevice.fromId(_selectedAddress);
      _device = target;

      _connectionSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _statusController.add('Disconnected');
        }
      });

      await _device!.connect(timeout: const Duration(seconds: 10));
      final services = await _device!.discoverServices();

      BluetoothCharacteristic? found;
      for (final service in services) {
        if (service.uuid == serviceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == characteristicUuid) {
              found = characteristic;
              break;
            }
          }
        }
      }

      if (found == null) {
        _statusController.add('FFE1 not found');
        return;
      }

      _notifyChar = found;
      await _notifyChar!.setNotifyValue(true);
      _notifySub = _notifyChar!.lastValueStream.listen(_handlePacket);

      _statusController.add('Connected and listening');
    } catch (e) {
      _statusController.add('Connect failed: $e');
    }
  }

  void _handlePacket(List<int> bytes) {
    if (bytes.isEmpty) return;

    final text = utf8.decode(bytes, allowMalformed: true);
    _buffer += text;

    while (true) {
      final crlf = _buffer.indexOf('\r\n');
      if (crlf >= 0) {
        final line = _buffer.substring(0, crlf).trim();
        _buffer = _buffer.substring(crlf + 2);
        if (line.isNotEmpty) {
          _consumeLogicalLine(line);
        }
        continue;
      }

      if (_buffer.contains('VIN=') &&
          _buffer.contains('CUR=') &&
          _buffer.contains('TEMP=')) {
        final line = _buffer.trim();
        _buffer = '';
        _consumeLogicalLine(line);
      }
      break;
    }
  }

  void _consumeLogicalLine(String line) {
    _lastRawLine = line;
    _rawController.add(line);

    _statusController.add('Connected and listening');

    final parsed = parseMitStyleLine(line);
    if (parsed != null) {
      _currentData = parsed;
      _dataController.add(parsed);
    }
  }

  BatteryData? parseMitStyleLine(String line) {
    try {
      final normalized = line.replaceAll(',', ' ').replaceAll('  ', ' ');
      final vMatch = RegExp(
        r'VIN\s*=\s*([-+]?[0-9]*\.?[0-9]+)',
        caseSensitive: false,
      ).firstMatch(normalized);
      final cMatch = RegExp(
        r'CUR\s*=\s*([-+]?[0-9]*\.?[0-9]+)',
        caseSensitive: false,
      ).firstMatch(normalized);
      final tMatch = RegExp(
        r'TEMP\s*=\s*([-+]?[0-9]*\.?[0-9]+)',
        caseSensitive: false,
      ).firstMatch(normalized);

      if (vMatch == null || cMatch == null || tMatch == null) {
        return null;
      }

      final voltage = double.parse(vMatch.group(1)!);
      final current = double.parse(cMatch.group(1)!);
      final temperature = double.parse(tMatch.group(1)!);

      return BatteryData(
        voltage: voltage,
        current: current,
        temperature: temperature,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> disconnect() async {
    try {
      await _notifySub?.cancel();
      _notifySub = null;

      await _connectionSub?.cancel();
      _connectionSub = null;

      if (_device != null) {
        await _device!.disconnect();
      }

      _device = null;
      _notifyChar = null;

      _statusController.add('Disconnected');
    } catch (e) {}
  }

  void dispose() {
    _notifySub?.cancel();
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _dataController.close();
    _statusController.close();
    _rawController.close();
    _scanResultsController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/battery_data.dart';

class BleService {
  // AI Thinker UUIDs confirmed from nRF Connect
  static final Guid serviceUuid =
      Guid('55535343-FE7D-4AE5-8FA9-9FAFD205E455');
  static final Guid notifyUuid =
      Guid('49535343-1E4D-4BD9-BA61-23C647249616');
  static final Guid writeUuid =
      Guid('49535343-8841-43F4-A8D4-ECBE34729BB3');

  static const String _selectedAddressKey = 'selected_ble_address';

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
  BluetoothCharacteristic? _writeChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  final Map<String, ScanResult> _scanMap = {};

  String _buffer = '';
  String _lastRawLine = '';
  BatteryData _currentData = BatteryData.empty;
  String _selectedAddress = '';
  bool _isConnected = false;

  String get selectedAddress => _selectedAddress;
  String get lastRawLine => _lastRawLine;
  BluetoothDevice? get device => _device;
  bool get isConnected => _isConnected;

  Future<bool> _ensureScanPermissions() async {
    final location = await Permission.location.request();
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();

    final ok = location.isGranted && scan.isGranted && connect.isGranted;
    if (!ok) {
      _statusController.add('Permission denied');
    }
    return ok;
  }

  Future<void> initialize() async {
    _selectedAddress = await _loadSavedAddress();
    _isConnected = false;
    _statusController.add('Disconnected');

    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final advName = r.advertisementData.advName.trim();
        final platformName = r.device.platformName.trim();
        final displayName = advName.isNotEmpty ? advName : platformName;

        // Filter out nameless BLE devices completely.
        if (displayName.isEmpty) continue;

        _scanMap[r.device.remoteId.str] = r;
      }
      _scanResultsController.add(_scanMap.values.toList());
    });
  }

  Future<String> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_selectedAddressKey) ?? '').trim();
  }

  Future<void> _saveSelectedAddress(String address) async {
    final trimmed = address.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_selectedAddressKey);
      return;
    }
    await prefs.setString(_selectedAddressKey, trimmed);
  }

  void setSelectedAddress(String address) {
    _selectedAddress = address.trim();
    unawaited(_saveSelectedAddress(_selectedAddress));
    _statusController.add('Selected: $_selectedAddress');
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final allowed = await _ensureScanPermissions();
    if (!allowed) return;

    _statusController.add('Scanning...');
    _scanMap.clear();
    _scanResultsController.add([]);
    await FlutterBluePlus.stopScan();
    await Future.delayed(const Duration(milliseconds: 400));
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _statusController.add('Scan stopped');
  }

  Future<void> connectAuto() async {
    if (_selectedAddress.isEmpty) {
      _statusController.add('Ready');
      return;
    }
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
          _isConnected = false;
          _statusController.add('Disconnected');
        }
      });

      await _device!.connect(timeout: const Duration(seconds: 10));
      final services = await _device!.discoverServices();

      BluetoothCharacteristic? foundNotify;
      BluetoothCharacteristic? foundWrite;
      for (final service in services) {
        if (service.uuid == serviceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == notifyUuid) {
              foundNotify = characteristic;
            } else if (characteristic.uuid == writeUuid) {
              foundWrite = characteristic;
            }
          }
        }
      }

      if (foundNotify == null || foundWrite == null) {
        _isConnected = false;
        _statusController.add(
          'AI Thinker notify/write characteristic not found',
        );
        await _device?.disconnect();
        return;
      }

      _notifyChar = foundNotify;
      _writeChar = foundWrite;

      await _notifyChar!.setNotifyValue(true);
      await _notifySub?.cancel();
      _notifySub = _notifyChar!.lastValueStream.listen(_handlePacket);

      await _saveSelectedAddress(_selectedAddress);
      _isConnected = true;
      _statusController.add('Connected and listening');
    } catch (e) {
      _isConnected = false;
      _statusController.add('Connect failed: $e');
      try {
        await _device?.disconnect();
      } catch (_) {}
    }
  }

  Future<void> sendText(String text, {bool appendCrLf = false}) async {
    if (_writeChar == null) {
      _statusController.add('Write failed: not connected');
      return;
    }

    final payload = appendCrLf ? '$text\r\n' : text;
    await _writeChar!.write(utf8.encode(payload), withoutResponse: false);
  }

  void _handlePacket(List<int> bytes) {
    if (bytes.isEmpty) return;

    final text = utf8.decode(bytes, allowMalformed: true);
    _buffer += text;

    while (true) {
      final crlf = _buffer.indexOf('\r\n');
      if (crlf < 0) break;

      final line = _buffer.substring(0, crlf).trim();
      _buffer = _buffer.substring(crlf + 2);

      if (line.isNotEmpty) {
        _consumeLogicalLine(line);
      }
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

      _isConnected = false;
      _device = null;
      _notifyChar = null;
      _writeChar = null;

      _statusController.add('Disconnected');
    } catch (_) {}
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

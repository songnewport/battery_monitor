import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const BatteryMonitorApp());
}

class BatteryMonitorApp extends StatelessWidget {
  const BatteryMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battery Monitor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07142D),
        useMaterial3: true,
      ),
      home: const BatteryMonitorHomePage(),
    );
  }
}

class BatteryMonitorHomePage extends StatefulWidget {
  const BatteryMonitorHomePage({super.key});

  @override
  State<BatteryMonitorHomePage> createState() => _BatteryMonitorHomePageState();
}

class _BatteryMonitorHomePageState extends State<BatteryMonitorHomePage> {
  // Fixed BLE address from MIT version
  static const String targetDeviceId = "68:5E:1C:2B:64:44";

  // DSD TECH / HM-10 UART service + characteristic
  static const String serviceUuidShort = "FFE0";
  static const String charUuidShort = "FFE1";

  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;

  StreamSubscription<List<ScanResult>>? scanSub;
  StreamSubscription<List<int>>? notifySub;
  StreamSubscription<BluetoothConnectionState>? connectionSub;

  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;

  String statusText = "Starting...";
  String rawData = "No data";
  String rxBuffer = "";

  double? voltage;
  double? current;
  double? temperature;
  double? power;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    scanSub?.cancel();
    notifySub?.cancel();
    connectionSub?.cancel();
    FlutterBluePlus.stopScan();
    targetDevice?.disconnect();
    super.dispose();
  }

  Future<void> startScan() async {
    if (!mounted) return;

    setState(() {
      isScanning = true;
      isConnecting = false;
      isConnected = false;
      statusText = "Scanning...";
    });

    await scanSub?.cancel();

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final id = r.device.remoteId.toString().toUpperCase();

        debugPrint("Found device name: ${r.device.platformName}");
        debugPrint("Found device id  : $id");

        if (id == targetDeviceId.toUpperCase()) {
          debugPrint("Target matched: $id");

          targetDevice = r.device;

          await FlutterBluePlus.stopScan();
          await scanSub?.cancel();

          if (mounted) {
            setState(() {
              isScanning = false;
              statusText = "Target found, connecting...";
            });
          }

          await connectDevice(r.device);
          break;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 6),
      );
    } catch (e) {
      debugPrint("Scan error: $e");
      if (!mounted) return;
      setState(() {
        isScanning = false;
        statusText = "Scan error";
      });
      return;
    }

    Future.delayed(const Duration(seconds: 7), () {
      if (!mounted) return;
      if (!isConnected && statusText == "Scanning...") {
        setState(() {
          isScanning = false;
          statusText = "Target not found";
        });
      }
    });
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    if (!mounted) return;

    setState(() {
      isConnecting = true;
      statusText = "Connecting...";
    });

    try {
      await device.disconnect();
    } catch (_) {}

    try {
      await device.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Connect note: $e");
    }

    connectionSub = device.connectionState.listen((state) {
      debugPrint("Connection state: $state");

      if (!mounted) return;

      if (state == BluetoothConnectionState.connected) {
        setState(() {
          isConnected = true;
          isConnecting = false;
          statusText = "Connected";
        });
      } else if (state == BluetoothConnectionState.disconnected) {
        setState(() {
          isConnected = false;
          isConnecting = false;
          statusText = "Disconnected, rescanning...";
        });
      }
    });

    await discoverAndSubscribe(device);
  }

  Future<void> discoverAndSubscribe(BluetoothDevice device) async {
    if (!mounted) return;

    setState(() {
      statusText = "Discovering services...";
    });

    final services = await device.discoverServices();

    for (final service in services) {
      final serviceUuid = service.uuid.toString().toUpperCase();
      debugPrint("Service: $serviceUuid");

      if (serviceUuid.contains(serviceUuidShort)) {
        for (final characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toString().toUpperCase();
          debugPrint("Characteristic: $charUuid");

          if (charUuid.contains(charUuidShort)) {
            targetCharacteristic = characteristic;

            await characteristic.setNotifyValue(true);

            notifySub = characteristic.lastValueStream.listen((value) {
              final incoming = String.fromCharCodes(value);

              debugPrint("BLE RAW BYTES: $value");
              debugPrint("BLE TEXT     : [$incoming]");

              appendAndParseBuffer(incoming);

              if (mounted) {
                setState(() {
                  statusText = "Connected and listening";
                });
              }
            });

            if (mounted) {
              setState(() {
                statusText = "Connected and listening";
                isConnected = true;
                isConnecting = false;
              });
            }
            return;
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      statusText = "FFE0 / FFE1 not found";
    });
  }

  // MIT-style idea:
  // 1. append incoming chunk to buffer
  // 2. wait until a full line arrives (\r\n)
  // 3. parse one complete line
  void appendAndParseBuffer(String incoming) {
    if (incoming.isEmpty) return;

    rxBuffer += incoming;

    // Keep raw view useful
    setState(() {
      rawData = rxBuffer;
    });

    // A full line ends with CRLF from your module
    while (rxBuffer.contains('\r\n')) {
      final endIndex = rxBuffer.indexOf('\r\n');
      final line = rxBuffer.substring(0, endIndex).trim();

      // Remove parsed line + CRLF from buffer
      rxBuffer = rxBuffer.substring(endIndex + 2);

      if (line.isEmpty) {
        continue;
      }

      debugPrint("FULL LINE => [$line]");
      parseMitStyleLine(line);

      if (mounted) {
        setState(() {
          rawData = line;
        });
      }
    }
  }

  // Parse one full line like:
  // VIN=0.6V CUR=20.0A TEMP=28.6C
  void parseMitStyleLine(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty) return;

    debugPrint("parseMitStyleLine => [$cleaned]");

    // Split by spaces, matching the actual nRF Connect log
    final parts = cleaned.split(RegExp(r'\s+'));

    double? vinValue;
    double? curValue;
    double? tempValue;

    for (final part in parts) {
      if (part.startsWith('VIN=')) {
        final text = part.replaceAll('VIN=', '').replaceAll('V', '').trim();
        vinValue = double.tryParse(text);
      } else if (part.startsWith('CUR=')) {
        final text = part.replaceAll('CUR=', '').replaceAll('A', '').trim();
        curValue = double.tryParse(text);
      } else if (part.startsWith('TEMP=')) {
        final text = part.replaceAll('TEMP=', '').replaceAll('C', '').trim();
        tempValue = double.tryParse(text);
      }
    }

    if (mounted) {
      setState(() {
        if (vinValue != null) {
          voltage = vinValue;
        }
        if (curValue != null) {
          current = curValue;
        }
        if (tempValue != null) {
          temperature = tempValue;
        }
        if (voltage != null && current != null) {
          power = voltage! * current!;
        }
      });
    }
  }

  Future<void> reconnect() async {
    await notifySub?.cancel();
    await connectionSub?.cancel();
    await scanSub?.cancel();

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    try {
      await targetDevice?.disconnect();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      targetDevice = null;
      targetCharacteristic = null;
      isConnected = false;
      isConnecting = false;
      isScanning = false;
      statusText = "Restarting scan...";
      rawData = "No data";
      rxBuffer = "";
    });

    await startScan();
  }

  String formatValue(double? value, int decimals) {
    if (value == null) return '--';
    return value.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final connectedText = isConnected ? 'Connected' : 'Disconnected';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF07142D),
              Color(0xFF0A1E45),
              Color(0xFF07142D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Battery Monitor',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFF1B4F78).withOpacity(0.90)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        connectedText,
                        style: const TextStyle(
                          color: Color(0xFFD8F0FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      MetricCard(
                        icon: Icons.battery_6_bar_rounded,
                        title: 'VOLTAGE',
                        value: formatValue(voltage, 2),
                        unit: 'V',
                      ),
                      const SizedBox(height: 18),
                      MetricCard(
                        icon: Icons.bolt_rounded,
                        title: 'CURRENT',
                        value: formatValue(current, 2),
                        unit: 'A',
                      ),
                      const SizedBox(height: 18),
                      MetricCard(
                        icon: Icons.thermostat_rounded,
                        title: 'TEMPERATURE',
                        value: formatValue(temperature, 1),
                        unit: '°C',
                      ),
                      const SizedBox(height: 18),
                      MetricCard(
                        icon: Icons.flash_on_rounded,
                        title: 'POWER',
                        value: formatValue(power, 1),
                        unit: 'W',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 240,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2A3F7A),
                          Color(0xFF314A8C),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: const Color(0xFF11224A),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Options',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListTile(
                                      leading: const Icon(Icons.refresh, color: Color(0xFF8FD2FF)),
                                      title: const Text('Reconnect'),
                                      subtitle: Text(statusText),
                                      onTap: () {
                                        Navigator.pop(context);
                                        reconnect();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.memory, color: Color(0xFF8FD2FF)),
                                      title: const Text('Raw data'),
                                      subtitle: Text(rawData, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.bluetooth, color: Color(0xFF8FD2FF)),
                                      title: const Text('Target address'),
                                      subtitle: const Text(targetDeviceId),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: const Center(
                          child: Text(
                            'OPTIONS',
                            style: TextStyle(
                              color: Color(0xFFDCEBFF),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 56,
              color: const Color(0xFF8FD2FF),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFD7E6FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Color(0xFFE7F1FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

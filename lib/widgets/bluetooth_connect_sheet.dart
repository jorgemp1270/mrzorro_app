import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/theme_service.dart';

class BluetoothConnectSheet extends StatefulWidget {
  final String userId;

  const BluetoothConnectSheet({super.key, required this.userId});

  @override
  State<BluetoothConnectSheet> createState() => _BluetoothConnectSheetState();
}

class _BluetoothConnectSheetState extends State<BluetoothConnectSheet> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  String? _statusMessage;

  // UUIDs for the Service and Characteristic
  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() {
          _adapterState = state;
        });
        if (state == BluetoothAdapterState.on) {
          _startScan();
        }
      }
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    _stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    // Check permissions
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      try {
        setState(() {
          _isScanning = true;
          _scanResults = [];
          _statusMessage = null;
        });

        _scanResultsSubscription = FlutterBluePlus.scanResults.listen((
          results,
        ) {
          if (mounted) {
            setState(() {
              _scanResults = results;
            });
          }
        });

        // Start scanning for the specific service UUID
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 15),
          withServices: [_serviceUuid],
        );

        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _statusMessage = 'Error al escanear: $e';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = 'Permisos de Bluetooth denegados';
        });
      }
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Conectando a ${device.platformName}...';
    });

    try {
      await device.connect();
      if (mounted) {
        setState(() {
          _connectedDevice = device;
          _statusMessage = 'Conectado. Enviando datos...';
        });
      }

      await _sendUserId(device);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Error de conexión: $e';
        });
      }
    }
  }

  Future<void> _sendUserId(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? writeCharacteristic;

      // Find the specific service and characteristic
      for (var service in services) {
        if (service.uuid == _serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == _characteristicUuid) {
              writeCharacteristic = characteristic;
              break;
            }
          }
        }
        if (writeCharacteristic != null) break;
      }

      if (writeCharacteristic != null) {
        await writeCharacteristic.write(utf8.encode(widget.userId));
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _statusMessage = '¡Datos enviados con éxito!';
          });

          // Disconnect after a delay
          Future.delayed(const Duration(seconds: 2), () {
            device.disconnect();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conexión exitosa con Mr. Zorro')),
              );
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _statusMessage =
                'No se encontró el servicio o característica correcta';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Error al enviar datos: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: currentTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Conectar con Mr. Zorro',
                style: (currentFont.style ?? const TextStyle()).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Asegúrate de que tu Bluetooth esté encendido para encontrar dispositivos cercanos.',
                style: (currentFont.style ?? const TextStyle()).copyWith(
                  fontSize: 14,
                  color: currentTheme.textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),

              if (_adapterState != BluetoothAdapterState.on)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bluetooth_disabled,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bluetooth apagado. Por favor actívalo.',
                          style: TextStyle(color: currentTheme.textColor),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      color:
                          _statusMessage!.contains('Error')
                              ? Colors.red
                              : currentTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (_adapterState == BluetoothAdapterState.on) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dispositivos encontrados:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: currentTheme.textColor,
                      ),
                    ),
                    if (_isScanning)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: currentTheme.primaryColor,
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: currentTheme.primaryColor,
                        ),
                        onPressed: _startScan,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SizedBox(
                    height: 200,
                    child:
                        _scanResults.isEmpty
                            ? Center(
                              child: Text(
                                _isScanning
                                    ? 'Buscando...'
                                    : 'No se encontraron dispositivos',
                                style: TextStyle(
                                  color: currentTheme.textColor.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _scanResults.length,
                              itemBuilder: (context, index) {
                                final result = _scanResults[index];
                                final deviceName =
                                    result.device.platformName.isNotEmpty
                                        ? result.device.platformName
                                        : 'Dispositivo desconocido';

                                return ListTile(
                                  title: Text(
                                    deviceName,
                                    style: TextStyle(
                                      color: currentTheme.textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    result.device.remoteId.toString(),
                                    style: TextStyle(
                                      color: currentTheme.textColor.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          currentTheme.primaryColor,
                                      foregroundColor: currentTheme.textColor,
                                    ),
                                    onPressed:
                                        _isConnecting
                                            ? null
                                            : () =>
                                                _connectToDevice(result.device),
                                    child: const Text('Conectar'),
                                  ),
                                );
                              },
                            ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

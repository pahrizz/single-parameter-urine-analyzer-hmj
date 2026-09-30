import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

import '../models/measurement_model.dart';
import '../services/database_helper.dart';
import '../services/export_service.dart';
import '../services/usb_service.dart';
import '../utils/constants.dart';
import '../widgets/history_list.dart';
import '../widgets/result_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UsbService _usb = UsbService();
  StreamSubscription<String>? _usbJsonSub;
  StreamSubscription<UsbEvent>? _usbEventSub;

  String _selectedParameter = AppConstants.parameterGlucose;
  Measurement? _currentReading;
  final List<Measurement> _historyList = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _usbJsonSub = _usb.dataStream.listen(
      (message) => unawaited(_handleSerialJson(message)),
      onError: (_) {},
    );
    _tryAttachUsbWatcher();
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    try {
      final list = await DatabaseHelper.instance.getMeasurements();
      if (!mounted) {
        return;
      }
      setState(() {
        _historyList
          ..clear()
          ..addAll(list);
        if (list.isNotEmpty) {
          _currentReading = list.first;
          _selectedParameter = list.first.parameterType;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load measurement history')),
        );
      }
    }
  }

  Future<void> _persistMeasurement(Measurement reading) async {
    try {
      await DatabaseHelper.instance.insertMeasurement(reading);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save measurement')),
        );
      }
    }
  }

  void _tryAttachUsbWatcher() {
    try {
      final stream = UsbSerial.usbEventStream;
      if (stream == null) {
        return;
      }
      _usbEventSub = stream.listen((UsbEvent event) {
        if (!mounted) {
          return;
        }
        if (event.event == UsbEvent.ACTION_USB_DETACHED) {
          unawaited(_usb.disconnect().then((_) {
            if (mounted) {
              setState(() {});
            }
          }));
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _usbJsonSub?.cancel();
    _usbEventSub?.cancel();
    _usb.dispose();
    super.dispose();
  }

  Future<void> _handleSerialJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        return;
      }
      final map = Map<String, dynamic>.from(decoded);
      final paramRaw = map['parameter'];
      final valueRaw = map['value'];
      if (paramRaw == null || valueRaw == null) {
        return;
      }
      final param = paramRaw.toString();
      if (!AppConstants.parameterOptions.contains(param)) {
        return;
      }
      final double? value = switch (valueRaw) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s),
        _ => null,
      };
      if (value == null) {
        return;
      }
      final status = AppConstants.categorizeValue(param, value);
      final reading = Measurement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        parameterType: param,
        value: value,
        categoryStatus: status,
      );
      await _persistMeasurement(reading);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedParameter = param;
        _currentReading = reading;
        _historyList.insert(0, reading);
      });
    } catch (_) {}
  }

  Future<void> _openUsbDevicePicker() async {
    final devices = await _usb.getAvailableDevices();
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('USB serial devices'),
          content: SizedBox(
            width: double.maxFinite,
            child: devices.isEmpty
                ? const Text(
                    'No devices found. Connect an OTG serial adapter and grant USB permission.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, i) {
                      final d = devices[i];
                      final label =
                          d.productName ?? d.manufacturerName ?? d.deviceName;
                      final vid = d.vid?.toRadixString(16) ?? '?';
                      final pid = d.pid?.toRadixString(16) ?? '?';
                      return ListTile(
                        leading: const Icon(Icons.usb),
                        title: Text(label),
                        subtitle: Text('VID $vid · PID $pid'),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          final ok = await _usb.connect(d);
                          if (!mounted) {
                            return;
                          }
                          setState(() {});
                          if (!ok) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open USB serial port'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            if (_usb.isConnected)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _usb.disconnect();
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: const Text('Disconnect'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Clear all measurement history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await DatabaseHelper.instance.clearHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        _historyList.clear();
        _currentReading = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not clear history')),
        );
      }
    }
  }

  Future<void> _simulateReading() async {
    double value;
    switch (_selectedParameter) {
      case AppConstants.parameterProtein:
        value = 3.0 + _random.nextInt(701) / 100.0;
        break;
      case AppConstants.parameterGlucose:
        value = (50 + _random.nextInt(101)).toDouble();
        break;
      case AppConstants.parameterSalinity:
        value = (120 + _random.nextInt(41)).toDouble();
        break;
      default:
        value = 0;
    }

    final status = AppConstants.categorizeValue(_selectedParameter, value);
    final reading = Measurement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      parameterType: _selectedParameter,
      value: value,
      categoryStatus: status,
    );

    await _persistMeasurement(reading);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentReading = reading;
      _historyList.insert(0, reading);
    });
  }

  Future<void> _exportCsv() async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing export...')),
    );
    try {
      final list = await DatabaseHelper.instance.getMeasurements();
      await ExportService().exportHistoryToCSV(list);
    } on StateError catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayMatchesSelection =
        _currentReading?.parameterType == _selectedParameter;

    return Scaffold(
      backgroundColor: AppConstants.clinicalBackground,
      appBar: AppBar(
        title: const Text('Medical Fluid Analyzer'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.share),
            onPressed: () => unawaited(_exportCsv()),
          ),
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearHistory,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.usb,
              color: _usb.isConnected ? Colors.green : Colors.red,
            ),
          ),
          IconButton(
            tooltip: 'Choose USB serial device',
            icon: const Icon(Icons.sensors),
            onPressed: _openUsbDevicePicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Parameter',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppConstants.clinicalSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.clinicalBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedParameter,
                    borderRadius: BorderRadius.circular(10),
                    items: AppConstants.parameterOptions
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(
                              p,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedParameter = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ResultCard(
                parameterType: _selectedParameter,
                timestamp: displayMatchesSelection
                    ? _currentReading?.timestamp
                    : null,
                value: displayMatchesSelection ? _currentReading?.value : null,
                status: displayMatchesSelection
                    ? _currentReading?.categoryStatus
                    : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _simulateReading,
                icon: const Icon(Icons.biotech_outlined),
                label: const Text('Simulate Reading'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppConstants.clinicalPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppConstants.clinicalPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: HistoryList(measurements: _historyList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

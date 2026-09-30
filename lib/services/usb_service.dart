import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

class UsbService {
  UsbService();

  UsbPort? _port;
  StreamSubscription<Uint8List>? _inputSub;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  String _carry = '';

  Stream<String> get dataStream => _dataController.stream;

  bool get isConnected => _port != null;

  Future<List<UsbDevice>> getAvailableDevices() async {
    try {
      return await UsbSerial.listDevices();
    } catch (_) {
      return [];
    }
  }

  Future<bool> connect(UsbDevice device) async {
    await disconnect();
    try {
      final port = await device.create();
      if (port == null) {
        return false;
      }
      if (await port.open() != true) {
        return false;
      }
      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      _port = port;
      _carry = '';
      _inputSub = port.inputStream?.listen(
        _onBytes,
        onError: (_) {},
        cancelOnError: false,
      );
      return true;
    } catch (_) {
      await disconnect();
      return false;
    }
  }

  Future<void> disconnect() async {
    await _inputSub?.cancel();
    _inputSub = null;
    try {
      await _port?.close();
    } catch (_) {}
    _port = null;
    _carry = '';
  }

  void dispose() {
    unawaited(disconnect());
    unawaited(_dataController.close());
  }

  void _onBytes(Uint8List data) {
    try {
      _carry += utf8.decode(data, allowMalformed: true);
      final (complete, remainder) = _drainCompleteJsonObjects(_carry);
      _carry = remainder;
      for (final jsonObject in complete) {
        if (!_dataController.isClosed) {
          _dataController.add(jsonObject);
        }
      }
    } catch (_) {}
  }
}

(List<String> complete, String remainder) _drainCompleteJsonObjects(
  String buffer,
) {
  final complete = <String>[];
  var rest = buffer;
  while (true) {
    final start = rest.indexOf('{');
    if (start < 0) {
      return (complete, '');
    }
    if (start > 0) {
      rest = rest.substring(start);
    }
    final endIdx = _closingBraceIndex(rest, 0);
    if (endIdx == null) {
      return (complete, rest);
    }
    complete.add(rest.substring(0, endIdx + 1));
    rest = rest.substring(endIdx + 1);
  }
}

int? _closingBraceIndex(String s, int openBraceIndex) {
  var depth = 0;
  var inString = false;
  var escape = false;
  for (var i = openBraceIndex; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (escape) {
      escape = false;
      continue;
    }
    if (inString) {
      if (c == 0x5C) {
        escape = true;
      } else if (c == 0x22) {
        inString = false;
      }
      continue;
    }
    if (c == 0x22) {
      inString = true;
      continue;
    }
    if (c == 0x7B) {
      depth++;
    } else if (c == 0x7D) {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return null;
}

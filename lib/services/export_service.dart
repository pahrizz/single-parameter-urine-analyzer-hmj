import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/measurement_model.dart';

class ExportService {
  Future<void> exportHistoryToCSV(List<Measurement> measurements) async {
    if (measurements.isEmpty) {
      throw StateError('No measurements to export');
    }

    final rows = <List<dynamic>>[
      ['ID', 'Timestamp', 'Parameter', 'Value', 'Status'],
    ];

    for (final m in measurements) {
      rows.add([
        m.id,
        m.timestamp.toIso8601String(),
        m.parameterType,
        m.value,
        m.categoryStatus,
      ]);
    }

    final csvString = csv.encode(rows);
    final dir = await getTemporaryDirectory();
    final filePath = p.join(dir.path, 'urine_analyzer_data.csv');
    final file = File(filePath);
    await file.writeAsString(csvString, encoding: utf8);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Urine Analyzer Data Export',
      ),
    );
  }
}

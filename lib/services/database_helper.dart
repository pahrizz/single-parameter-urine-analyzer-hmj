import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/measurement_model.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'urine_analyzer.db';
  static const String _table = 'measurements';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            parameterType TEXT NOT NULL,
            value REAL NOT NULL,
            categoryStatus TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertMeasurement(Measurement measurement) async {
    try {
      final db = await database;
      await db.insert(_table, measurement.toMap());
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Measurement>> getMeasurements() async {
    try {
      final db = await database;
      final rows = await db.query(
        _table,
        orderBy: 'timestamp DESC',
      );
      return rows.map(Measurement.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final db = await database;
      await db.delete(_table);
    } catch (_) {
      rethrow;
    }
  }
}

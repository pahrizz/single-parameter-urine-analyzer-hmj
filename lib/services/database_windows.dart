import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite via FFI for Windows, Linux, and macOS desktop builds.
///
/// Call once before any `DatabaseHelper` / `sqflite` access on desktop.
void setupSqliteForDesktop() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

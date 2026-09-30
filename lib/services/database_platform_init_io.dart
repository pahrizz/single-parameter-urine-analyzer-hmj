import 'dart:io' show Platform;

import 'database_windows.dart';

void initDatabasePlatform() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setupSqliteForDesktop();
  }
}

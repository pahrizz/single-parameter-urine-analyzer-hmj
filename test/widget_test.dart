import 'package:flutter_test/flutter_test.dart';
import 'package:single_parameter_urine_analyzer/main.dart';
import 'package:single_parameter_urine_analyzer/services/database_platform_init.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initDatabasePlatform();

  testWidgets('Dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(const UrineAnalyzerApp());
    await tester.pump();

    expect(find.text('Medical Fluid Analyzer'), findsOneWidget);
    expect(find.text('Simulate Reading'), findsOneWidget);
  });
}

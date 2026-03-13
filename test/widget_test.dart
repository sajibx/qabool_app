// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/main.dart';
import 'package:qabool_app/services/api_service.dart';
import 'package:qabool_app/services/auth_service.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    final apiService = ApiService();
    final authService = AuthService(apiService);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: authService,
        child: const QaboolApp(),
      ),
    );

    expect(find.byType(QaboolApp), findsOneWidget);
  });
}

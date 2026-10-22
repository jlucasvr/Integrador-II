import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const ValueKey('login-email')), 'gestor@example.test');
  await tester.enterText(
      find.byKey(const ValueKey('login-password')), 'test-password');
  await tapVisible(tester, find.text('Entrar'));
}

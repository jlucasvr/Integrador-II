import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapSearchControl(WidgetTester tester, Finder target) async {
  await Scrollable.ensureVisible(tester.element(target), alignment: .35);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> chooseSearchItem(
  WidgetTester tester, {
  String term = 'Água potável',
}) async {
  if (find.byKey(const ValueKey('search-term')).evaluate().isEmpty) {
    await tapSearchControl(tester, find.text('Preciso de ajuda'));
  }
  await tester.enterText(find.byKey(const ValueKey('search-term')), term);
  await tester.pump();
  await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
}

Future<void> openWizardResults(
  WidgetTester tester, {
  String term = 'Água potável',
}) async {
  await chooseSearchItem(tester, term: term);
  await tapSearchControl(tester, find.byKey(const ValueKey('wizard-locate')));
  await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
}

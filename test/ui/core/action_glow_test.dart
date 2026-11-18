import 'package:apoio_app/ui/core/widgets/action_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget scene({
    required bool active,
    bool reduced = false,
    VoidCallback? onTap,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Center(
          child: ActionGlow(
            active: active,
            child: SizedBox(
              key: const ValueKey('target'),
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('halo surge, pulsa continuamente e não muda a área de clique', (
    tester,
  ) async {
    var clicked = false;
    await tester.pumpWidget(scene(active: true, onTap: () => clicked = true));
    expect(tester.binding.hasScheduledFrame, isTrue);
    final target = find.byKey(const ValueKey('target'));
    final bounds = tester.getRect(target);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1800));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.getRect(target), bounds);
    await tester.tap(find.byType(IconButton));
    expect(clicked, isTrue);
    await tester.pumpWidget(scene(active: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('action-glow')), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
  testWidgets('movimento reduzido mantém destaque estático sem ticker', (
    tester,
  ) async {
    await tester.pumpWidget(scene(active: true, reduced: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('action-glow')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(scene(active: true));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

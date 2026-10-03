import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_android/core/models/gateway_activity.dart';
import 'package:hermes_android/core/theme/hermes_theme.dart';
import 'package:hermes_android/core/widgets/gateway_activity_card.dart';

Future<void> _pump(
  WidgetTester tester,
  List<GatewayToolActivity> activities, {
  bool verbose = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: hermesTheme(Brightness.dark),
      home: Scaffold(
        body: ListView(
          children: [
            GatewayActivityCard(activities: activities, verbose: verbose),
          ],
        ),
      ),
    ),
  );
  // A running tool owns a live progress indicator, so pumpAndSettle would
  // correctly never settle. One animation frame is enough for assertions.
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('completed tool activity is collapsed with a compact summary', (
    tester,
  ) async {
    await _pump(tester, const [
      GatewayToolActivity(
        name: 'terminal',
        phase: GatewayToolActivityPhase.completed,
        durationSeconds: 4.2,
        detail: 'Build finished',
      ),
    ]);

    expect(find.text('工具活动'), findsOneWidget);
    expect(find.text('1 个已完成'), findsOneWidget);
    expect(find.text('Build finished'), findsNothing);

    await tester.tap(find.text('工具活动'));
    await tester.pumpAndSettle();

    expect(find.text('Build finished'), findsOneWidget);
    expect(find.text('耗时 4.2 s 完成'), findsOneWidget);
  });

  testWidgets('running activity opens automatically', (tester) async {
    await _pump(tester, const [
      GatewayToolActivity(
        name: 'browser_navigate',
        phase: GatewayToolActivityPhase.running,
        detail: 'Opening page',
      ),
    ]);

    expect(find.text('Opening page'), findsOneWidget);
    expect(find.text('运行中'), findsOneWidget);
  });

  testWidgets('failure summary is urgent and includes duration', (
    tester,
  ) async {
    await _pump(tester, const [
      GatewayToolActivity(
        name: 'terminal',
        phase: GatewayToolActivityPhase.failed,
        durationSeconds: 2,
        detail: 'Command failed',
      ),
    ]);

    expect(find.text('1 个失败 • 共 1 个'), findsOneWidget);
    await tester.tap(find.text('工具活动'));
    await tester.pumpAndSettle();
    expect(find.text('耗时 2.0 s 后失败'), findsOneWidget);
  });

  testWidgets('survives large text without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: hermesTheme(Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(
            body: ListView(
              children: const [
                GatewayActivityCard(
                  activities: [
                    GatewayToolActivity(
                      name: 'a_very_long_tool_name_that_must_not_overflow',
                      phase: GatewayToolActivityPhase.running,
                      detail: 'A long operation is currently running.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });
}

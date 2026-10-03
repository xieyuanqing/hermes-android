import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_android/core/screens/chat_screen.dart';

void main() {
  test('user bubble foreground passes WCAG AA in light and dark themes', () {
    final ratio = _contrastRatio(
      hermesUserMessageForeground,
      hermesUserMessageBubbleBackground,
    );

    expect(ratio, greaterThanOrEqualTo(4.5));
    // The pair is theme-independent, so the verified ratio applies to both.
    expect(hermesUserMessageBubbleBackground, const Color(0xFFD4AF37));
    expect(hermesUserMessageForeground, const Color(0xFF1C1B1F));
  });

  testWidgets('message bubble copies its original Markdown content', (
    WidgetTester tester,
  ) async {
    const message = 'Use `Hermes` from a **remote gateway**.';
    String? clipboardText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return {'text': clipboardText};
        default:
          return null;
      }
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MessageBubble(content: message, isUser: false)),
      ),
    );

    expect(find.byTooltip('复制消息'), findsNothing);
    expect(find.byKey(const Key('message-bubble')), findsOneWidget);

    await tester.longPress(find.byKey(const Key('message-bubble')));
    await tester.pumpAndSettle();
    expect(find.text('消息操作'), findsOneWidget);
    await tester.tap(find.byTooltip('复制消息'));
    await tester.pump();

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, message);
    expect(find.text('消息已复制'), findsOneWidget);
  });

  testWidgets('assistant message exposes a read aloud action', (
    WidgetTester tester,
  ) async {
    var readAloudCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            content: 'Răspuns Hermes.',
            isUser: false,
            onReadAloud: () async {
              readAloudCalls++;
            },
          ),
        ),
      ),
    );

    expect(find.byTooltip('朗读'), findsNothing);
    await tester.longPress(find.byKey(const Key('message-bubble')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('朗读'), findsOneWidget);
    await tester.tap(find.byTooltip('朗读'));
    await tester.pump();
    expect(readAloudCalls, 1);
  });

  testWidgets('user message does not expose read aloud', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageBubble(content: 'Mesaj utilizator.', isUser: true),
        ),
      ),
    );

    expect(find.byTooltip('复制消息'), findsNothing);
    expect(find.byTooltip('朗读'), findsNothing);
    await tester.longPress(find.byKey(const Key('message-bubble')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('复制消息'), findsOneWidget);
    expect(find.byTooltip('朗读'), findsNothing);
  });

  testWidgets('message actions wrap and retain semantics at font scale 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final semantics = tester.ensureSemantics();

    for (final width in [320.0, 360.0]) {
      tester.view.physicalSize = Size(width, 640);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: MessageBubble(
              content: 'A compact action layout.',
              isUser: false,
              onReadAloud: () async {},
              onEdit: () {},
              onRetry: () async {},
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(const Key('message-bubble')));
      await tester.pumpAndSettle();
      for (final label in const [
        '复制消息',
        '朗读',
        '编辑并重新发送',
        '重新生成响应',
      ]) {
        final action = find.bySemanticsLabel(label);
        expect(action, findsOneWidget);
        expect(tester.getRect(action).height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);

      // Dismiss through the barrier so the next width starts from a closed
      // sheet: a modal route outlives pumpWidget and would obscure the bubble.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    }
    semantics.dispose();
  });

  testWidgets('message hierarchy labels user and assistant prose', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MessageBubble(content: 'Question', isUser: true),
              MessageBubble(content: 'Answer', isUser: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('你'), findsOneWidget);
    expect(find.text('Hermes'), findsOneWidget);
  });

  testWidgets('message bubble stays within a tablet chat column', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1704, 1136);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final isUser in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                key: const Key('chat-column'),
                constraints: const BoxConstraints(maxWidth: 800),
                child: MessageBubble(
                  content: List.filled(
                    30,
                    'Long tablet message content must wrap inside the chat column.',
                  ).join(' '),
                  isUser: isUser,
                ),
              ),
            ),
          ),
        ),
      );

      final columnRect = tester.getRect(find.byKey(const Key('chat-column')));
      final bubbleRect = tester.getRect(
        find.byKey(const Key('message-bubble')),
      );
      expect(bubbleRect.width, lessThanOrEqualTo(columnRect.width));
      expect(bubbleRect.left, greaterThanOrEqualTo(columnRect.left));
      expect(bubbleRect.right, lessThanOrEqualTo(columnRect.right));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fenced code has language, copy, and wrap controls', (
    tester,
  ) async {
    String? clipboardText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            content: '```dart\nvoid main() => print("Hermes");\n```',
            isUser: false,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('markdown-code-block')), findsOneWidget);
    expect(find.text('dart'), findsOneWidget);
    expect(find.byTooltip('复制代码'), findsOneWidget);
    expect(find.byTooltip('自动换行'), findsOneWidget);

    await tester.tap(find.byTooltip('复制代码'));
    await tester.pump();
    expect(clipboardText, 'void main() => print("Hermes");\n');

    await tester.tap(find.byTooltip('自动换行'));
    await tester.pump();
    expect(find.byTooltip('单行横向滚动'), findsOneWidget);
  });
}

double _contrastRatio(Color first, Color second) {
  final light = _relativeLuminance(first);
  final dark = _relativeLuminance(second);
  final lighter = light > dark ? light : dark;
  final darker = light > dark ? dark : light;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double linearize(double channel) {
    final value = channel;
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}

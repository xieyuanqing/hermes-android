import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_android/core/services/android_launch_intent_service.dart';
import 'package:hermes_android/core/services/android_share_intent_service.dart';
import 'package:hermes_android/core/services/connection_manager.dart';
import 'package:hermes_android/core/theme/hermes_theme.dart';
import 'package:hermes_android/core/utils/new_chat_options.dart';
import 'package:hermes_android/core/utils/relative_time.dart';
import 'package:hermes_android/core/widgets/hermes_shell.dart';
import 'package:hermes_android/core/widgets/more_pane.dart';
import 'package:hermes_android/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCredentialStore implements CredentialStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  String? readCached(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real app provides standard Chinese Material controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final manager = await ConnectionManager.create(
      await SharedPreferences.getInstance(),
      credentialStore: _FakeCredentialStore(),
    );
    await tester.pumpWidget(app.HermesApp(connManager: manager));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(app.HomeScreen));
    final labels = MaterialLocalizations.of(context);
    expect(Localizations.localeOf(context), const Locale('zh', 'CN'));
    expect(labels.copyButtonLabel, '复制');
    expect(labels.pasteButtonLabel, '粘贴');
    expect(labels.selectAllButtonLabel, '全选');
    expect(labels.cutButtonLabel, '剪切');
    expect(labels.okButtonLabel, '确定');
    expect(labels.cancelButtonLabel, '取消');
    expect(labels.backButtonTooltip, '返回');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('real workspace shell renders Chinese navigation', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: hermesTheme(Brightness.light),
        home: HermesShell(
          builder: (context, destination) =>
              Center(child: Text('pane:${destination.name}')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['首页', '会话', '项目', '动态', '更多']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('会话'));
    await tester.pumpAndSettle();
    expect(find.text('pane:chats'), findsOneWidget);
  });

  test('Chinese terminology and relative-time units use actual APIs', () {
    final entries = buildMoreSections(dashboardReachable: false)
        .expand((section) => section.entries);
    expect(
      entries.firstWhere((entry) => entry.id == 'ai-filing').unavailableReason,
      '需要 Hermes Gateway 支持根据用户修正持续改进的归档接口。',
    );
    expect(NewChatMode.projectChat.label, '项目会话');
    expect(NewChatMode.quickChat.label, '快速会话');
    final now = DateTime.utc(2026, 10, 3, 15);
    expect(formatRelativeTime(now, now.millisecondsSinceEpoch / 1000), '刚刚');
    expect(
      formatRelativeTime(
        now,
        now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch / 1000,
      ),
      '5 分钟前',
    );
  });

  testWidgets('real startup recovery remains Chinese for corrupted saved data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'saved_connections': <String>['{invalid-json'],
    });
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channels = [
      MethodChannel(AndroidShareIntentService.channelName),
      MethodChannel(AndroidLaunchIntentService.channelName),
    ];
    for (final channel in channels) {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
    }
    addTearDown(() {
      for (final channel in channels) {
        messenger.setMockMethodCallHandler(channel, null);
        channel.setMethodCallHandler(null);
      }
    });

    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Hermes 无法加载您保存的连接'), findsOneWidget);
    expect(find.text('重置已保存连接'), findsOneWidget);
    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context), const Locale('zh', 'CN'));
    expect(MaterialLocalizations.of(context).copyButtonLabel, '复制');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('saved_connections'), <String>['{invalid-json']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

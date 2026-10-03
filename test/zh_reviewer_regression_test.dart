import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_android/core/services/connection_manager.dart';
import 'package:hermes_android/core/services/text_size_preference.dart';
import 'package:hermes_android/core/utils/relative_time.dart';
import 'package:hermes_android/core/widgets/hermes_shell.dart';
import 'package:hermes_android/core/widgets/more_pane.dart';
import 'package:hermes_android/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ReviewCredentialStore implements CredentialStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  String? readCached(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('review: real app starts in Chinese with localized Material menus', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final manager = await ConnectionManager.create(
      prefs,
      credentialStore: _ReviewCredentialStore(),
    );

    await tester.pumpWidget(HermesApp(connManager: manager));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeScreen));
    expect(Localizations.localeOf(context), const Locale('zh', 'CN'));
    expect(MaterialLocalizations.of(context).copyButtonLabel, '复制');
    expect(MaterialLocalizations.of(context).pasteButtonLabel, '粘贴');
    expect(find.text('暂无连接'), findsOneWidget);
    expect(find.text('No connections'), findsNothing);

    await tester.tap(find.byTooltip('添加连接'));
    await tester.pumpAndSettle();
    expect(find.text('添加 Gateway 连接'), findsOneWidget);
    expect(find.text('主机'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('review: translated roadmap capabilities remain unavailable', () {
    for (final reachable in [false, true]) {
      final entries = {
        for (final section in buildMoreSections(
          dashboardReachable: reachable,
        ))
          for (final entry in section.entries) entry.id: entry,
      };
      for (final id in ['assets', 'pin-batch-undo', 'ai-filing']) {
        final entry = entries[id]!;
        expect(entry.availability, MoreEntryAvailability.unavailable);
        expect(entry.isSelectable, isFalse);
        expect(entry.unavailableReason, contains('Hermes Gateway'));
        expect(entry.title, matches(RegExp(r'[\u4e00-\u9fff]')));
      }
      expect(
        entries['files']!.availability,
        reachable
            ? MoreEntryAvailability.available
            : MoreEntryAvailability.unavailable,
      );
    }
  });

  test('review: localization leaves navigation and preference identifiers intact', () {
    expect(HermesDestination.values.map((value) => value.name), [
      'home',
      'chats',
      'projects',
      'activity',
      'more',
    ]);
    expect(TextSizePreference.values.map((value) => value.storageValue), [
      'system',
      'small',
      'default',
      'large',
      'extra_large',
    ]);
  });

  test('review: relative-time units are Chinese at window boundaries', () {
    final now = DateTime.utc(2026, 10, 3, 12);
    String label(Duration age) => formatRelativeTime(
      now,
      now.subtract(age).millisecondsSinceEpoch / 1000,
    );
    expect(label(const Duration(seconds: 30)), '刚刚');
    expect(label(const Duration(minutes: 3)), '3 分钟前');
    expect(label(const Duration(hours: 2)), '2 小时前');
    expect(label(const Duration(days: 2)), '2 天前');
  });
}

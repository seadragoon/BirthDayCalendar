import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/shared/theme/app_theme.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/widgets/theme_selection_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemeData Custom Background Tests', () {
    test('default AppThemeData has null customBackgroundPath and default opacity 0.80', () {
      const standard = AppThemeData.standard;
      expect(standard.customBackgroundPath, isNull);
      expect(standard.backgroundOpacity, 0.80);
    });

    test('copyWith updates customBackgroundPath and backgroundOpacity', () {
      const standard = AppThemeData.standard;
      final updated = standard.copyWith(
        customBackgroundPath: '/path/to/image.jpg',
        backgroundOpacity: 0.65,
      );

      expect(updated.customBackgroundPath, '/path/to/image.jpg');
      expect(updated.backgroundOpacity, 0.65);
    });

    test('copyWith with clearCustomBackground clears path', () {
      final themeWithBg = AppThemeData.standard.copyWith(
        customBackgroundPath: '/path/to/image.jpg',
      );
      expect(themeWithBg.customBackgroundPath, '/path/to/image.jpg');

      final cleared = themeWithBg.copyWith(clearCustomBackground: true);
      expect(cleared.customBackgroundPath, isNull);
    });
  });

  group('ThemeNotifier Custom Background Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial build loads defaults when no custom bg is stored', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = await container.read(themeProvider.future);
      expect(theme.customBackgroundPath, isNull);
      expect(theme.backgroundOpacity, 0.80);
    });

    test('setBackgroundOpacity clamps and persists value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期化完了を待つ
      await container.read(themeProvider.future);

      await container.read(themeProvider.notifier).setBackgroundOpacity(0.90);
      final updated = container.read(themeProvider).requireValue;
      expect(updated.backgroundOpacity, 0.90);

      // SharedPreferences の値を確認
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('theme_bg_opacity'), 0.90);
    });

    test('clearCustomBackgroundImage clears path and SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.future);

      // clear を呼ぶ
      await container.read(themeProvider.notifier).clearCustomBackgroundImage();
      final theme = container.read(themeProvider).requireValue;
      expect(theme.customBackgroundPath, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('theme_custom_bg_path'), isFalse);
    });
  });

  group('ThemeSelectionModal Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders Photo Background section and picker card when unconfigured', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelectionModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 「オリジナル背景設定」セクションが表示される
      expect(find.text('オリジナル背景設定'), findsOneWidget);
      // 「アルバムから写真を選ぶ」カードが表示される
      expect(find.text('アルバムから写真を選ぶ'), findsOneWidget);
      expect(find.text('好きな写真をカレンダー背景に設定'), findsOneWidget);
    });
  });
}

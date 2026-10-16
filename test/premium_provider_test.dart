import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';
import 'package:birthday_calendar/features/settings/widgets/basic_settings_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state defaults to false when SharedPreferences is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isPremium = await container.read(isPremiumProvider.future);
      expect(isPremium, isFalse);
    });

    test('loads persisted true value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        kDebugIsPremiumKey: true,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isPremium = await container.read(isPremiumProvider.future);
      expect(isPremium, isTrue);
    });

    test('setDebugPremium updates state and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期化
      await container.read(isPremiumProvider.future);

      // true に更新
      await container.read(isPremiumProvider.notifier).setDebugPremium(true);
      expect(container.read(isPremiumProvider).value, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kDebugIsPremiumKey), isTrue);

      // false に更新
      await container.read(isPremiumProvider.notifier).setDebugPremium(false);
      expect(container.read(isPremiumProvider).value, isFalse);
      expect(prefs.getBool(kDebugIsPremiumKey), isFalse);
    });

    test('toggleDebugPremium inverts premium status', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      expect(container.read(isPremiumProvider).value, isFalse);

      // 1回目のトグル -> true
      await container.read(isPremiumProvider.notifier).toggleDebugPremium();
      expect(container.read(isPremiumProvider).value, isTrue);

      // 2回目のトグル -> false
      await container.read(isPremiumProvider.notifier).toggleDebugPremium();
      expect(container.read(isPremiumProvider).value, isFalse);
    });
  });

  group('BasicSettingsModal Debug Switch Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders debug premium switch in debug environment and toggles value', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BasicSettingsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 最下部までスクロール
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // 開発者メニューが表示されていることを確認
      expect(find.text('開発者メニュー (Debug Only)'), findsOneWidget);
      expect(find.text('【開発用】プレミアム状態モック'), findsOneWidget);
      expect(find.textContaining('無料プラン'), findsOneWidget);

      // スイッチをタップして切り替え
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsWidgets); // 通知等のSwitchもあるためfindsWidgets

      final mockSwitchFinder = find.widgetWithText(SwitchListTile, '【開発用】プレミアム状態モック');
      expect(mockSwitchFinder, findsOneWidget);

      await tester.tap(mockSwitchFinder);
      await tester.pumpAndSettle();

      // プレミアム有効に切り替わっていることを確認
      expect(find.textContaining('プレミアム有効'), findsOneWidget);
    });
  });
}

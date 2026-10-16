import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/shared/theme/app_theme.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/widgets/theme_selection_modal.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Premium Theme Data Tests', () {
    test('AppThemeType contains all 8 themes', () {
      expect(AppThemeType.values.length, 8);
      expect(AppThemeType.values, containsAll([
        AppThemeType.standard,
        AppThemeType.sakura,
        AppThemeType.night,
        AppThemeType.mint,
        AppThemeType.cafe,
        AppThemeType.sunset,
        AppThemeType.rose,
        AppThemeType.ocean,
      ]));
    });

    test('AppThemeData.values has 8 themes configured', () {
      expect(AppThemeData.values.length, 8);
    });

    test('isPremium correctly identifies standard vs premium themes', () {
      expect(AppThemeData.standard.isPremium, isFalse);
      expect(AppThemeData.sakura.isPremium, isFalse);
      expect(AppThemeData.night.isPremium, isFalse);

      expect(AppThemeData.mint.isPremium, isTrue);
      expect(AppThemeData.cafe.isPremium, isTrue);
      expect(AppThemeData.sunset.isPremium, isTrue);
      expect(AppThemeData.rose.isPremium, isTrue);
      expect(AppThemeData.ocean.isPremium, isTrue);
    });

    test('Premium themes have proper assets and colors assigned', () {
      // mint
      expect(AppThemeData.mint.backgroundImagePath, 'assets/images/themes/mint.jpg');
      expect(AppThemeData.mint.primaryColor, const Color(0xFF26A69A));
      expect(AppThemeData.mint.label, 'ミント（ボタニカル）');

      // cafe
      expect(AppThemeData.cafe.backgroundImagePath, 'assets/images/themes/cafe.jpg');
      expect(AppThemeData.cafe.primaryColor, const Color(0xFF8D6E63));
      expect(AppThemeData.cafe.label, 'モカ（カフェ）');

      // sunset
      expect(AppThemeData.sunset.backgroundImagePath, 'assets/images/themes/sunset.jpg');
      expect(AppThemeData.sunset.primaryColor, const Color(0xFFFF7043));
      expect(AppThemeData.sunset.label, '夕暮れ（サンセット）');

      // rose
      expect(AppThemeData.rose.backgroundImagePath, 'assets/images/themes/rose.jpg');
      expect(AppThemeData.rose.primaryColor, const Color(0xFFC2185B));
      expect(AppThemeData.rose.label, 'ローズ（エレガント）');

      // ocean
      expect(AppThemeData.ocean.backgroundImagePath, 'assets/images/themes/ocean.jpg');
      expect(AppThemeData.ocean.primaryColor, const Color(0xFF00ACC1));
      expect(AppThemeData.ocean.label, '海（オーシャン）');
    });
  });

  group('ThemeSelectionModal Premium Section Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders premium themes section and all 5 premium options', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ThemeSelectionModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダーやセクション見出し
      expect(find.text('プリセットテーマ'), findsOneWidget);
      expect(find.text('プレミアム機能'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('プレミアム限定テーマ'), findsOneWidget);
      expect(find.text('PREMIUM'), findsNWidgets(2));

      // テーマオプションラベル
      expect(find.text('ミント（ボタニカル）'), findsOneWidget);
      expect(find.text('モカ（カフェ）'), findsOneWidget);
      expect(find.text('夕暮れ（サンセット）'), findsOneWidget);
      expect(find.text('ローズ（エレガント）'), findsOneWidget);
      expect(find.text('海（オーシャン）'), findsOneWidget);

      // 限定バッジの存在
      expect(find.text('限定'), findsNWidgets(5));
    });

    testWidgets('tapping premium theme when non-premium shows promo sheet and does not apply theme', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ThemeSelectionModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // プレミアム限定テーマ（ミント）をタップ
      await tester.tap(find.text('ミント（ボタニカル）'));
      await tester.pumpAndSettle();

      // プロモ案内シートが表示されていること
      expect(find.text('プレミアム限定機能'), findsOneWidget);
      expect(find.textContaining('ミント（ボタニカル） テーマ'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);

      // シートを閉じる
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(find.text('プレミアム限定機能'), findsNothing);
    });

    testWidgets('tapping premium theme when premium is active applies theme immediately without sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith(_AlwaysPremiumNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      await container.read(themeProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ThemeSelectionModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 解放時のヘッダー表示
      expect(find.text('プレミアム有効'), findsOneWidget);
      expect(find.text('PRO 会員'), findsOneWidget);
      expect(find.text('すべての限定テーマとオリジナル写真背景をご利用いただけます ✨'), findsOneWidget);

      // プレミアム限定テーマ（ミント）をタップ
      await tester.tap(find.text('ミント（ボタニカル）'));
      await tester.pumpAndSettle();

      // プロモシートは表示されない
      expect(find.text('プレミアム限定機能'), findsNothing);
    });

    test('ThemeNotifier restores standard theme and clears background image when updating primary color', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.future);

      // 1. きせかえテーマ（桜）を設定
      await container.read(themeProvider.notifier).setThemeType(AppThemeType.sakura);
      var current = container.read(themeProvider).requireValue;
      expect(current.type, AppThemeType.sakura);
      expect(current.backgroundImagePath, isNotEmpty);

      // 2. カラー変更を呼び出し
      const targetColor = Color(0xFF26A69A);
      await container.read(themeProvider.notifier).updatePrimaryColor(targetColor);

      current = container.read(themeProvider).requireValue;
      // 標準テーマに戻り、テーマ画像パスがクリアされ、指定色になっていること
      expect(current.type, AppThemeType.standard);
      expect(current.backgroundImagePath, isEmpty);
      expect(current.primaryColor, targetColor);
      expect(current.backgroundColor, Colors.white);
    });
  });
}

class _AlwaysPremiumNotifier extends PremiumNotifier {
  @override
  Future<bool> build() async => true;
}

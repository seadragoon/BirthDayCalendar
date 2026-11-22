import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/legal/views/legal_document_modal.dart';
import 'package:birthday_calendar/features/premium/models/premium_plan.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';
import 'package:birthday_calendar/features/premium/views/premium_paywall_modal.dart';
import 'package:birthday_calendar/features/settings/widgets/basic_settings_modal.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/widgets/custom_drawer.dart';
import 'package:birthday_calendar/shared/widgets/theme_selection_modal.dart';

class _FixedPremiumNotifier extends PremiumNotifier {
  final bool _initialValue;
  _FixedPremiumNotifier(this._initialValue);

  @override
  Future<bool> build() async => _initialValue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumPlan Model Tests', () {
    test('defines three plans with yearly recommended and free trial', () {
      expect(PremiumPlan.allPlans.length, 3);
      expect(PremiumPlan.yearly.isRecommended, isTrue);
      expect(PremiumPlan.yearly.hasFreeTrial, isTrue);
      expect(PremiumPlan.monthly.hasFreeTrial, isFalse);
      expect(PremiumPlan.lifetime.hasFreeTrial, isFalse);
    });
  });

  group('PremiumPaywallModal Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('defaults to yearly plan and switches CTA label dynamically', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PremiumPaywallModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態は年額プランのCTA
      expect(find.text('BirthDay Calendar Pro'), findsOneWidget);
      expect(find.text(PremiumPlan.yearly.ctaLabel), findsOneWidget);

      // 月額プランをタップ -> CTAが月額用に切り替わる
      await tester.tap(find.byKey(const ValueKey('premium_plan_monthly')));
      await tester.pumpAndSettle();
      expect(find.text(PremiumPlan.monthly.ctaLabel), findsOneWidget);

      // 買い切りプランをタップ -> CTAが買い切り用に切り替わる
      await tester.tap(find.byKey(const ValueKey('premium_plan_lifetime')));
      await tester.pumpAndSettle();
      expect(find.text(PremiumPlan.lifetime.ctaLabel), findsOneWidget);
    });

    testWidgets('shows featureTitle message when specified', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PremiumPaywallModal(featureTitle: 'オリジナル背景設定'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('「オリジナル背景設定」をはじめ、すべてのプレミアム機能を解放しましょう。'),
        findsOneWidget,
      );
    });

    testWidgets('tapping purchase CTA opens confirmation dialog and mock unlock works', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PremiumPaywallModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 購入CTAをタップ
      await tester.tap(
        find.byKey(const ValueKey('premium_purchase_cta_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('年額プランの確認'), findsOneWidget);
      expect(find.text('モック購入を完了'), findsOneWidget);

      // モック購入を完了 -> プレミアム有効状態に遷移
      await tester.tap(find.text('モック購入を完了'));
      await tester.pumpAndSettle();

      expect(find.text('プレミアムプラン（Pro）有効中'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('premium_purchase_cta_button')),
        findsNothing,
      );
    });

    testWidgets('tapping restore button shows feedback snackbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PremiumPaywallModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('premium_restore_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('購入履歴を確認しました'), findsOneWidget);
    });

    testWidgets('opens terms of service and privacy policy modals', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PremiumPaywallModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 利用規約をタップ
      await tester.ensureVisible(find.text('利用規約'));
      await tester.tap(find.text('利用規約'));
      await tester.pumpAndSettle();
      expect(find.byType(LegalDocumentModal), findsOneWidget);

      // 戻ってプライバシーポリシーをタップ
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('プライバシーポリシー'));
      await tester.tap(find.text('プライバシーポリシー'));
      await tester.pumpAndSettle();
      expect(find.byType(LegalDocumentModal), findsOneWidget);
    });

    testWidgets('shows active status card when user is already premium', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith(() => _FixedPremiumNotifier(true)),
          ],
          child: const MaterialApp(
            home: PremiumPaywallModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRO 会員'), findsOneWidget);
      expect(find.text('プレミアムプラン（Pro）有効中'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('premium_purchase_cta_button')),
        findsNothing,
      );
    });
  });

  group('Paywall Navigation Entry Points Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('opens PremiumPaywallModal from CustomDrawer', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(themeProvider.future);
      await container.read(isPremiumProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CustomDrawer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Proにアップグレード'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Proにアップグレード'), findsOneWidget);
      await tester.tap(find.text('Proにアップグレード'));
      await tester.pumpAndSettle();

      expect(find.byType(PremiumPaywallModal), findsOneWidget);
    });

    testWidgets('opens PremiumPaywallModal from BasicSettingsModal', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BasicSettingsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Proにアップグレード'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Proにアップグレード'), findsOneWidget);
      await tester.tap(find.text('Proにアップグレード'));
      await tester.pumpAndSettle();

      expect(find.byType(PremiumPaywallModal), findsOneWidget);
    });

    testWidgets(
      'opens PremiumPaywallModal from ThemeSelectionModal promo sheet',
      (tester) async {
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

        // 限定テーマをタップ -> 案内シートが開く
        await tester.tap(find.text('ミント（ボタニカル）'));
        await tester.pumpAndSettle();
        expect(find.text('プレミアムプランを見る'), findsOneWidget);

        // 「プレミアムプランを見る」をタップ -> Paywallが開く
        await tester.tap(find.text('プレミアムプランを見る'));
        await tester.pumpAndSettle();

        expect(find.byType(PremiumPaywallModal), findsOneWidget);
        expect(find.textContaining('ミント（ボタニカル） テーマ'), findsOneWidget);
      },
    );
  });
}

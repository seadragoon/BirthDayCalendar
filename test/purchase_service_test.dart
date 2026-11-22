import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/premium/models/premium_plan.dart';
import 'package:birthday_calendar/features/premium/models/purchase_outcome.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';
import 'package:birthday_calendar/features/premium/services/purchase_service.dart';
import 'package:birthday_calendar/features/premium/views/premium_paywall_modal.dart';

class _FakePurchaseService implements PurchaseService {
  @override
  bool get isConfigured => true;

  bool initialPremiumStatus;
  List<PremiumPlan> plansToReturn;
  PurchaseOutcome nextPurchaseOutcome;
  PurchaseOutcome nextRestoreOutcome;
  PremiumPlanType? lastPurchasedPlanType;

  final Set<PremiumStatusListener> _listeners = {};

  _FakePurchaseService({
    this.initialPremiumStatus = false,
    List<PremiumPlan>? plansToReturn,
    this.nextPurchaseOutcome = const PurchaseOutcome.success(
      isPremium: true,
      message: 'プレミアムプラン（Pro）が有効になりました！',
    ),
    this.nextRestoreOutcome = const PurchaseOutcome.success(
      isPremium: true,
      message: '購入を復元しました！プレミアム機能が有効です。',
    ),
  }) : plansToReturn = plansToReturn ?? PremiumPlan.allPlans;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> checkPremiumStatus() async => initialPremiumStatus;

  @override
  Future<List<PremiumPlan>> fetchPlans() async => plansToReturn;

  @override
  Future<PurchaseOutcome> purchasePlan(PremiumPlanType planType) async {
    lastPurchasedPlanType = planType;
    return nextPurchaseOutcome;
  }

  @override
  Future<PurchaseOutcome> restorePurchases() async => nextRestoreOutcome;

  @override
  void addPremiumStatusListener(PremiumStatusListener listener) {
    _listeners.add(listener);
  }

  @override
  void removePremiumStatusListener(PremiumStatusListener listener) {
    _listeners.remove(listener);
  }

  void emitPremiumStatus(bool isPremium) {
    for (final listener in List<PremiumStatusListener>.from(_listeners)) {
      listener(isPremium);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PurchaseService & PremiumProvider Integration Tests', () {
    test('reads initial premium status from configured PurchaseService', () async {
      final fakeService = _FakePurchaseService(initialPremiumStatus: true);
      final container = ProviderContainer(
        overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final isPremium = await container.read(isPremiumProvider.future);
      expect(isPremium, isTrue);
    });

    test('updates isPremiumProvider when realtime listener fires', () async {
      final fakeService = _FakePurchaseService(initialPremiumStatus: false);
      final container = ProviderContainer(
        overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      expect(await container.read(isPremiumProvider.future), isFalse);

      fakeService.emitPremiumStatus(true);
      expect(container.read(isPremiumProvider).value, isTrue);
    });

    test('purchasePlan activates premium state on success', () async {
      final fakeService = _FakePurchaseService(initialPremiumStatus: false);
      final container = ProviderContainer(
        overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      final outcome = await container
          .read(isPremiumProvider.notifier)
          .purchasePlan(PremiumPlanType.lifetime);

      expect(outcome.status, PurchaseStatus.success);
      expect(fakeService.lastPurchasedPlanType, PremiumPlanType.lifetime);
      expect(container.read(isPremiumProvider).value, isTrue);
    });

    test('purchasePlan keeps non-premium state on cancel', () async {
      final fakeService = _FakePurchaseService(
        initialPremiumStatus: false,
        nextPurchaseOutcome: const PurchaseOutcome.cancelled(),
      );
      final container = ProviderContainer(
        overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      final outcome = await container
          .read(isPremiumProvider.notifier)
          .purchasePlan(PremiumPlanType.monthly);

      expect(outcome.status, PurchaseStatus.cancelled);
      expect(container.read(isPremiumProvider).value, isFalse);
    });

    test('restorePurchases activates premium state when entitlement found', () async {
      final fakeService = _FakePurchaseService(initialPremiumStatus: false);
      final container = ProviderContainer(
        overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      final outcome =
          await container.read(isPremiumProvider.notifier).restorePurchases();

      expect(outcome.status, PurchaseStatus.success);
      expect(container.read(isPremiumProvider).value, isTrue);
    });
  });

  group('PremiumPaywallModal with Configured PurchaseService Tests', () {
    testWidgets('reflects dynamic store prices from premiumPlansProvider', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dynamicPlans = [
        PremiumPlan.yearly.copyWith(
          priceText: '¥2,200',
          ctaLabel: '7日間無料で始める（年額 ¥2,200）',
        ),
        PremiumPlan.monthly.copyWith(
          priceText: '¥300',
          ctaLabel: '月額 ¥300 で始める',
        ),
        PremiumPlan.lifetime.copyWith(
          priceText: '¥4,800',
          ctaLabel: '¥4,800 で永久に解放する',
        ),
      ];
      final fakeService = _FakePurchaseService(plansToReturn: dynamicPlans);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: PremiumPaywallModal()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¥2,200'), findsOneWidget);
      expect(find.text('7日間無料で始める（年額 ¥2,200）'), findsOneWidget);
    });

    testWidgets('executes real purchase flow and unlocks premium UI', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = _FakePurchaseService(initialPremiumStatus: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: PremiumPaywallModal()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('premium_purchase_cta_button')),
      );
      await tester.pumpAndSettle();

      expect(fakeService.lastPurchasedPlanType, PremiumPlanType.yearly);
      expect(find.text('プレミアムプラン（Pro）有効中'), findsOneWidget);
      expect(find.textContaining('プレミアムプラン（Pro）が有効になりました！'), findsOneWidget);
    });

    testWidgets('shows notFound snackbar when restore finds no history', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = _FakePurchaseService(
        initialPremiumStatus: false,
        nextRestoreOutcome: const PurchaseOutcome.notFound(
          message: '復元可能な有効な購入履歴が見つかりませんでした。',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [purchaseServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: PremiumPaywallModal()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('premium_restore_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('復元可能な有効な購入履歴が見つかりませんでした。'),
        findsOneWidget,
      );
    });
  });
}

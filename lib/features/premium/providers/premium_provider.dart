import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/premium/models/premium_plan.dart';
import 'package:birthday_calendar/features/premium/models/purchase_outcome.dart';
import 'package:birthday_calendar/features/premium/services/purchase_service.dart';

/// デバッグ用のSharedPreferences永続化キー
const String kDebugIsPremiumKey = 'debug_force_is_premium';

/// 課金サービスの DI Provider（テスト時はモック実装へ差し替え可能）
final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => RevenueCatPurchaseService.instance,
);

/// ストアから取得した最新プラン価格一覧（未設定・オフライン時はデフォルト価格へフォールバック）
final premiumPlansProvider = FutureProvider<List<PremiumPlan>>((ref) async {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return purchaseService.fetchPlans();
});

/// プレミアム状態（無料 or プレミアム会員）を管理する Notifier。
///
/// 【セキュリティ・安全対策】
/// - [kDebugMode] が false のリリースビルド環境では、安全のためデバッグ設定を一切参照せず
///   常に [PurchaseService]（RevenueCat）の検証結果のみを返します。
/// - デバッグ環境では SharedPreferences によるモック切替と RevenueCat 実課金の両方をサポートします。
class PremiumNotifier extends AsyncNotifier<bool> {
  void Function(bool)? _statusListener;

  @override
  Future<bool> build() async {
    final purchaseService = ref.watch(purchaseServiceProvider);

    // RevenueCat からのリアルタイム権限更新を購読
    _statusListener = (bool isPremiumFromStore) {
      if (isPremiumFromStore) {
        state = const AsyncData(true);
      } else if (!kDebugMode) {
        state = const AsyncData(false);
      }
    };
    purchaseService.addPremiumStatusListener(_statusListener!);
    ref.onDispose(() {
      if (_statusListener != null) {
        purchaseService.removePremiumStatusListener(_statusListener!);
      }
    });

    // デバッグビルド時はデバッグモック設定を優先チェック
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      final debugOverride = prefs.getBool(kDebugIsPremiumKey);
      if (debugOverride == true) {
        return true;
      }
    }

    // RevenueCat SDK が初期化済みならストア側のEntitlementを確認
    if (purchaseService.isConfigured) {
      return purchaseService.checkPremiumStatus();
    }

    return false;
  }

  /// 指定プランの購入を実行し、成功時にプレミアム状態を更新
  Future<PurchaseOutcome> purchasePlan(PremiumPlanType planType) async {
    final purchaseService = ref.read(purchaseServiceProvider);
    final outcome = await purchaseService.purchasePlan(planType);
    if (outcome.status == PurchaseStatus.success && outcome.isPremium) {
      state = const AsyncData(true);
    }
    return outcome;
  }

  /// 過去の購入履歴を復元し、有効な権限があればプレミアム状態を更新
  Future<PurchaseOutcome> restorePurchases() async {
    final purchaseService = ref.read(purchaseServiceProvider);
    final outcome = await purchaseService.restorePurchases();
    if (outcome.status == PurchaseStatus.success && outcome.isPremium) {
      state = const AsyncData(true);
    }
    return outcome;
  }

  /// デバッグ用：プレミアム状態を切り替える（無料 ⇄ プレミアム）
  Future<void> toggleDebugPremium() async {
    if (!kDebugMode) return;

    final current = state.value ?? false;
    await setDebugPremium(!current);
  }

  /// デバッグ用：プレミアム状態を明示的に設定する
  Future<void> setDebugPremium(bool value) async {
    if (!kDebugMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kDebugIsPremiumKey, value);
    state = AsyncData(value);
  }
}

/// ユーザーがプレミアム会員かどうかを判定する Provider。
final isPremiumProvider = AsyncNotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);

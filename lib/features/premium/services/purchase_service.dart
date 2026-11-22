import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:birthday_calendar/features/premium/models/premium_plan.dart';
import 'package:birthday_calendar/features/premium/models/purchase_config.dart';
import 'package:birthday_calendar/features/premium/models/purchase_outcome.dart';

/// プレミアム状態のリアルタイム変更を受け取るコールバック
typedef PremiumStatusListener = void Function(bool isPremium);

/// アプリ内課金（IAP）サービスの抽象インターフェース。
///
/// テスト時やプラットフォーム切替時にDIで差し替え可能にするため抽象化しています。
abstract class PurchaseService {
  /// 課金SDKが初期化済みかつ利用可能か
  bool get isConfigured;

  /// SDKの初期化（アプリ起動時に一度呼び出す）
  Future<void> initialize();

  /// 現在のプレミアム有効状態をストア／RevenueCatから取得
  Future<bool> checkPremiumStatus();

  /// ストアから最新の価格・プラン一覧を取得（未設定・失敗時はフォールバックを返却）
  Future<List<PremiumPlan>> fetchPlans();

  /// 指定プランの購入を実行
  Future<PurchaseOutcome> purchasePlan(PremiumPlanType planType);

  /// 過去の購入履歴を復元（Restore）
  Future<PurchaseOutcome> restorePurchases();

  /// プレミアム状態変更リスナーを登録
  void addPremiumStatusListener(PremiumStatusListener listener);

  /// プレミアム状態変更リスナーを解除
  void removePremiumStatusListener(PremiumStatusListener listener);
}

/// RevenueCat (`purchases_flutter`) を用いたアプリ内課金サービス実装。
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService._();

  static final RevenueCatPurchaseService instance =
      RevenueCatPurchaseService._();

  bool _isConfigured = false;
  final Map<PremiumPlanType, Package> _packageCache = {};
  final Set<PremiumStatusListener> _listeners = {};
  bool _customerInfoListenerRegistered = false;

  @override
  bool get isConfigured => _isConfigured;

  @override
  Future<void> initialize() async {
    if (_isConfigured) return;
    if (!PurchaseConfig.hasConfiguredApiKey) {
      debugPrint(
        '[RevenueCat] APIキー未設定または非対応プラットフォームのため初期化をスキップしました。',
      );
      return;
    }

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final configuration = PurchasesConfiguration(
        PurchaseConfig.currentPlatformApiKey,
      );
      await Purchases.configure(configuration);

      if (!_customerInfoListenerRegistered) {
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
        _customerInfoListenerRegistered = true;
      }

      _isConfigured = true;
    } catch (e) {
      debugPrint('[RevenueCat] 初期化エラー: $e');
      _isConfigured = false;
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    final isPremium = _hasActiveProEntitlement(customerInfo);
    for (final listener in List<PremiumStatusListener>.from(_listeners)) {
      listener(isPremium);
    }
  }

  bool _hasActiveProEntitlement(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(
      PurchaseConfig.entitlementId,
    );
  }

  @override
  Future<bool> checkPremiumStatus() async {
    if (!_isConfigured) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _hasActiveProEntitlement(customerInfo);
    } catch (e) {
      debugPrint('[RevenueCat] 顧客情報取得エラー: $e');
      return false;
    }
  }

  @override
  Future<List<PremiumPlan>> fetchPlans() async {
    if (!_isConfigured) return PremiumPlan.allPlans;

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        return PremiumPlan.allPlans;
      }

      _packageCache.clear();
      if (current.annual != null) {
        _packageCache[PremiumPlanType.yearly] = current.annual!;
      }
      if (current.monthly != null) {
        _packageCache[PremiumPlanType.monthly] = current.monthly!;
      }
      if (current.lifetime != null) {
        _packageCache[PremiumPlanType.lifetime] = current.lifetime!;
      }

      return PremiumPlan.allPlans.map((basePlan) {
        final pkg = _packageCache[basePlan.type];
        if (pkg == null) return basePlan;

        final storePrice = pkg.storeProduct.priceString;
        final ctaLabel = switch (basePlan.type) {
          PremiumPlanType.yearly => '7日間無料で始める（年額 $storePrice）',
          PremiumPlanType.monthly => '月額 $storePrice で始める',
          PremiumPlanType.lifetime => '$storePrice で永久に解放する',
        };

        return basePlan.copyWith(
          productId: pkg.storeProduct.identifier,
          priceText: storePrice,
          ctaLabel: ctaLabel,
        );
      }).toList();
    } catch (e) {
      debugPrint('[RevenueCat] Offerings取得エラー: $e');
      return PremiumPlan.allPlans;
    }
  }

  @override
  Future<PurchaseOutcome> purchasePlan(PremiumPlanType planType) async {
    if (!_isConfigured) {
      return const PurchaseOutcome.notConfigured();
    }

    try {
      var package = _packageCache[planType];
      if (package == null) {
        await fetchPlans();
        package = _packageCache[planType];
      }

      if (package == null) {
        return const PurchaseOutcome.error(
          '選択されたプランの商品情報をストアから取得できませんでした。時間をおいて再度お試しください。',
        );
      }

      final result = await Purchases.purchase(PurchaseParams.package(package));
      final isPremium = _hasActiveProEntitlement(result.customerInfo);
      if (isPremium) {
        return const PurchaseOutcome.success(
          isPremium: true,
          message: 'プレミアムプラン（Pro）が有効になりました！',
        );
      }
      return const PurchaseOutcome.error(
        '購入処理は完了しましたが、権限の反映を確認できませんでした。「購入を復元する」をお試しください。',
      );
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome.cancelled();
      }
      return PurchaseOutcome.error(_localizeErrorMessage(errorCode));
    } catch (e) {
      debugPrint('[RevenueCat] 購入エラー: $e');
      return const PurchaseOutcome.error(
        '購入処理中にエラーが発生しました。ネットワーク接続を確認して再度お試しください。',
      );
    }
  }

  @override
  Future<PurchaseOutcome> restorePurchases() async {
    if (!_isConfigured) {
      return const PurchaseOutcome.notConfigured();
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium = _hasActiveProEntitlement(customerInfo);
      if (isPremium) {
        return const PurchaseOutcome.success(
          isPremium: true,
          message: '購入を復元しました！プレミアム機能が有効です。',
        );
      }
      return const PurchaseOutcome.notFound(
        message: '復元可能な有効な購入履歴が見つかりませんでした。',
      );
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      return PurchaseOutcome.error(_localizeErrorMessage(errorCode));
    } catch (e) {
      debugPrint('[RevenueCat] 復元エラー: $e');
      return const PurchaseOutcome.error(
        '購入の復元中にエラーが発生しました。時間をおいて再度お試しください。',
      );
    }
  }

  @override
  void addPremiumStatusListener(PremiumStatusListener listener) {
    _listeners.add(listener);
  }

  @override
  void removePremiumStatusListener(PremiumStatusListener listener) {
    _listeners.remove(listener);
  }

  String _localizeErrorMessage(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return 'ネットワークに接続できません。通信環境を確認して再度お試しください。';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'この端末ではアプリ内課金が許可されていません。端末の設定をご確認ください。';
      case PurchasesErrorCode.purchaseInvalidError:
        return '購入情報が無効です。ストアアカウントの設定をご確認ください。';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'すでに購入済みのプランです。「購入を復元する」をお試しください。';
      case PurchasesErrorCode.paymentPendingError:
        return 'お支払いが保留中です。承認が完了すると自動的に反映されます。';
      default:
        return 'ストア処理中にエラーが発生しました。時間をおいて再度お試しください。';
    }
  }
}

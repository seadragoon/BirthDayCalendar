import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/ads/services/ad_service.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';

/// 広告サービスの DI Provider（テスト時はモック実装へ差し替え可能）
final adServiceProvider = Provider<AdService>(
  (ref) => AdMobService.instance,
);

/// 広告を表示すべきかどうかを判定する Provider。
///
/// - プレミアム会員（`isPremium == true`）またはプレミアム判定ロード中は常に `false`（完全非表示）
/// - 無料ユーザーかつ広告SDKが利用可能なプラットフォーム・設定時のみ `true`
final shouldShowAdsProvider = Provider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  if (!adService.isAvailable) return false;

  final isPremiumAsync = ref.watch(isPremiumProvider);
  // プレミアム状態の読み込み中やプレミアム有効時は広告を表示しない
  return isPremiumAsync.maybeWhen(
    data: (isPremium) => !isPremium,
    orElse: () => false,
  );
});

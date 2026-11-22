/// 課金・購入復元処理の結果ステータス
enum PurchaseStatus {
  /// 処理成功（プレミアム有効化）
  success,

  /// ユーザーによるキャンセル
  cancelled,

  /// 課金SDK未設定（APIキー未注入または非対応プラットフォーム）
  notConfigured,

  /// 復元対象の有効な購入履歴が見つからなかった
  notFound,

  /// ネットワーク・ストア側などのエラー
  error,
}

/// 購入または購入復元処理の結果モデル
class PurchaseOutcome {
  final PurchaseStatus status;
  final bool isPremium;
  final String? message;

  const PurchaseOutcome({
    required this.status,
    this.isPremium = false,
    this.message,
  });

  const PurchaseOutcome.success({bool isPremium = true, String? message})
      : this(
          status: PurchaseStatus.success,
          isPremium: isPremium,
          message: message,
        );

  const PurchaseOutcome.cancelled()
      : this(status: PurchaseStatus.cancelled, isPremium: false);

  const PurchaseOutcome.notConfigured()
      : this(status: PurchaseStatus.notConfigured, isPremium: false);

  const PurchaseOutcome.notFound({String? message})
      : this(
          status: PurchaseStatus.notFound,
          isPremium: false,
          message: message,
        );

  const PurchaseOutcome.error(String message)
      : this(
          status: PurchaseStatus.error,
          isPremium: false,
          message: message,
        );
}

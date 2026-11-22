/// プレミアムプランの種別（月額 / 年額 / 買い切り）
enum PremiumPlanType {
  /// 月額サブスクリプション
  monthly,

  /// 年額サブスクリプション（7日間無料トライアル・一番お得）
  yearly,

  /// 買い切り（Lifetime）
  lifetime,
}

/// プレミアムプランの料金・表示情報モデル。
///
/// ステップ4（RevenueCat / ストア課金連携）導入時は、ストアから取得した
/// 価格・通貨情報で動的に生成するベースモデルとして利用します。
class PremiumPlan {
  /// プラン種別
  final PremiumPlanType type;

  /// ストア課金用プロダクトID（プレースホルダ）
  final String productId;

  /// プラン表示名
  final String title;

  /// 価格表示テキスト（例: ¥1,980）
  final String priceText;

  /// 課金周期テキスト（例: / 年）
  final String periodText;

  /// 補足テキスト（月額換算や説明）
  final String subText;

  /// 強調バッジ（例: 一番お得・7日間無料）
  final String? badgeText;

  /// 選択時にCTAボタンへ表示するアクション文言
  final String ctaLabel;

  /// 無料トライアル対象かどうか
  final bool hasFreeTrial;

  /// 推奨プランかどうか
  final bool isRecommended;

  const PremiumPlan({
    required this.type,
    required this.productId,
    required this.title,
    required this.priceText,
    required this.periodText,
    required this.subText,
    this.badgeText,
    required this.ctaLabel,
    this.hasFreeTrial = false,
    this.isRecommended = false,
  });

  /// 年額プラン（推奨・デフォルト選択）
  static const PremiumPlan yearly = PremiumPlan(
    type: PremiumPlanType.yearly,
    productId: 'birthday_calendar_pro_yearly',
    title: '年額プラン',
    priceText: '¥1,980',
    periodText: '/ 年',
    subText: '月あたり ¥165（約41%OFF・7日間無料体験）',
    badgeText: '一番お得・7日間無料',
    ctaLabel: '7日間無料で始める（年額 ¥1,980）',
    hasFreeTrial: true,
    isRecommended: true,
  );

  /// 月額プラン
  static const PremiumPlan monthly = PremiumPlan(
    type: PremiumPlanType.monthly,
    productId: 'birthday_calendar_pro_monthly',
    title: '月額プラン',
    priceText: '¥280',
    periodText: '/ 月',
    subText: 'まずは気軽にお試し・いつでも解約可能',
    badgeText: null,
    ctaLabel: '月額 ¥280 で始める',
    hasFreeTrial: false,
    isRecommended: false,
  );

  /// 買い切りプラン（Lifetime）
  static const PremiumPlan lifetime = PremiumPlan(
    type: PremiumPlanType.lifetime,
    productId: 'birthday_calendar_pro_lifetime',
    title: '買い切り（Lifetime）',
    priceText: '¥4,200',
    periodText: '一回払い',
    subText: '追加料金なし・ずっとプレミアム機能を利用可能',
    badgeText: 'サブスクなし',
    ctaLabel: '¥4,200 で永久に解放する',
    hasFreeTrial: false,
    isRecommended: false,
  );

  /// 表示順のプラン一覧（推奨の年額プランを先頭に配置）
  static const List<PremiumPlan> allPlans = [
    yearly,
    monthly,
    lifetime,
  ];
}

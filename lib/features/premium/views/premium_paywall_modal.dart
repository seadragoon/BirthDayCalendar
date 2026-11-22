import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/legal/models/legal_texts.dart';
import 'package:birthday_calendar/features/legal/views/legal_document_modal.dart';
import 'package:birthday_calendar/features/premium/models/premium_plan.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';

/// プレミアムプラン（Pro）の料金案内・アップグレードモーダル（Paywall）。
///
/// - 王冠アイコン 👑 と特典ハイライトを表示
/// - 月額 / 年額（7日間無料・一番お得） / 買い切り（Lifetime）のプラン選択カード
/// - 選択プランに応じたCTAボタンの動的切り替え
/// - 購入復元（Restore）導線、利用規約・プライバシーポリシーへのリンク
/// - ステップ4（ストア決済連携）まではモック購入・デバッグ解放導線を提供
class PremiumPaywallModal extends ConsumerStatefulWidget {
  /// 特定のプレミアム機能から遷移してきた場合の機能名（任意）
  final String? featureTitle;

  const PremiumPaywallModal({
    super.key,
    this.featureTitle,
  });

  /// フルスクリーンモーダルとして Paywall を表示するヘルパー
  static Future<void> show(
    BuildContext context, {
    String? featureTitle,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PremiumPaywallModal(featureTitle: featureTitle),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  ConsumerState<PremiumPaywallModal> createState() =>
      _PremiumPaywallModalState();
}

class _PremiumPaywallModalState extends ConsumerState<PremiumPaywallModal> {
  PremiumPlanType _selectedPlanType = PremiumPlanType.yearly;
  bool _isProcessing = false;

  PremiumPlan get _selectedPlan => PremiumPlan.allPlans.firstWhere(
        (plan) => plan.type == _selectedPlanType,
        orElse: () => PremiumPlan.yearly,
      );

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 上部バー（閉じるボタン）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PRO 会員',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // メインコンテンツ（スクロール可能）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroHeader(isDark, isPremium),
                    const SizedBox(height: 24),
                    _buildBenefitsSection(isDark),
                    const SizedBox(height: 24),
                    if (!isPremium) ...[
                      Text(
                        'プランを選択',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...PremiumPlan.allPlans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildPlanCard(plan, isDark),
                        ),
                      ),
                    ] else ...[
                      _buildActivePremiumCard(isDark),
                    ],
                    const SizedBox(height: 8),
                    _buildLegalNoticeAndLinks(context, isDark),
                  ],
                ),
              ),
            ),

            // 固定フッターCTA（未解放時）
            if (!isPremium) _buildBottomCtaBar(context, isDark),
          ],
        ),
      ),
    );
  }

  /// 上部ヒーローヘッダー（王冠アイコン・タイトル・導入メッセージ）
  Widget _buildHeroHeader(bool isDark, bool isPremium) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'BirthDay Calendar Pro',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPremium
              ? 'プレミアムプランをご利用中です。すべての限定機能をお楽しみください！'
              : widget.featureTitle != null
                  ? '「${widget.featureTitle}」をはじめ、すべてのプレミアム機能を解放しましょう。'
                  : 'お気に入りの写真や限定テーマで、毎日のカレンダーをもっと特別に。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// プレミアム特典ハイライト一覧
  Widget _buildBenefitsSection(bool isDark) {
    const benefits = [
      (
        icon: Icons.photo_library_outlined,
        title: '自分の写真で背景きせかえ',
        subtitle: '推し・家族・ペットの写真をカレンダー背景に設定（濃さ調整付き）',
      ),
      (
        icon: Icons.palette_outlined,
        title: 'プレミアム限定テーマ 5種',
        subtitle: 'ミント・モカ・夕暮れ・ローズ・海の専用パレット＆背景が使い放題',
      ),
      (
        icon: Icons.widgets_outlined,
        title: '写真付きカウントダウンウィジェット',
        subtitle: 'ホーム画面で大切な人の写真と誕生日までの日数をいつでも確認',
      ),
      (
        icon: Icons.block_outlined,
        title: '広告の完全非表示（Ad-Free）',
        subtitle: '邪魔な広告を一切表示せず、すっきり快適にスケジュール管理',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Text(
                'Proプランに含まれるすべての特典',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(benefits.length, (index) {
            final item = benefits[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == benefits.length - 1 ? 0 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 18,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// プラン選択カード
  Widget _buildPlanCard(PremiumPlan plan, bool isDark) {
    final isSelected = _selectedPlanType == plan.type;
    final activeBorderColor = const Color(0xFFFF8F00);
    final cardBg = isSelected
        ? (isDark
            ? Colors.amber.shade900.withValues(alpha: 0.22)
            : const Color(0xFFFFF8E1))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('premium_plan_${plan.type.name}'),
        onTap: () {
          setState(() {
            _selectedPlanType = plan.type;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? activeBorderColor
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBorderColor.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // 選択ラジオインジケーター
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? activeBorderColor
                    : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                size: 22,
              ),
              const SizedBox(width: 12),

              // プラン名・バッジ・説明
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          plan.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (plan.badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: plan.isRecommended
                                  ? const Color(0xFFFF8F00)
                                  : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              plan.badgeText!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: plan.isRecommended
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey.shade200
                                        : Colors.grey.shade800),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.subText,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 価格表示
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceText,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark
                              ? Colors.amber.shade300
                              : const Color(0xFFE65100))
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  Text(
                    plan.periodText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// すでにプレミアム会員の場合のステータスカード
  Widget _buildActivePremiumCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.shade900.withValues(alpha: 0.25)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade600,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.amber.shade700,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            'プレミアムプラン（Pro）有効中',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '限定テーマ5種・オリジナル写真背景・写真付きカウントダウンウィジェットなど、すべての特典をご利用いただけます。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 下部固定の購入CTA・復元ボタンエリア
  Widget _buildBottomCtaBar(BuildContext context, bool isDark) {
    final plan = _selectedPlan;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              key: const ValueKey('premium_purchase_cta_button'),
              onPressed: _isProcessing ? null : () => _handlePurchase(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      plan.ctaLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('premium_restore_button'),
            onPressed: _isProcessing ? null : () => _handleRestore(context),
            child: Text(
              '購入を復元する（Restore）',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 注意書きおよび利用規約・プライバシーポリシーリンク
  Widget _buildLegalNoticeAndLinks(BuildContext context, bool isDark) {
    final mutedColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return Column(
      children: [
        Text(
          '※ サブスクリプション（月額・年額）は期間終了の24時間前までに解約しない限り自動更新されます。設定はご利用ストアのアカウント管理画面からいつでも変更できます。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.45,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalDocumentModal(
                      documentType: LegalDocumentType.termsOfService,
                    ),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: Text(
                '利用規約',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text('・', style: TextStyle(color: mutedColor)),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalDocumentModal(
                      documentType: LegalDocumentType.privacyPolicy,
                    ),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: Text(
                'プライバシーポリシー',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 購入ボタン押下時のモック処理（ステップ4でストア決済に接続）
  Future<void> _handlePurchase(BuildContext context) async {
    final plan = _selectedPlan;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFFF8F00)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${plan.title}の確認',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選択中のプラン: ${plan.title}（${plan.priceText} ${plan.periodText}）',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ストア決済連携は現在準備中です（ステップ4にて接続予定）。',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 10),
              Text(
                '【開発テスト用】下の「モック購入を完了」を押すと、プレミアム機能を即時解放できます。',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber.shade800,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
          ),
          if (kDebugMode)
            FilledButton(
              onPressed: () async {
                await ref
                    .read(isPremiumProvider.notifier)
                    .setDebugPremium(true);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('👑 プレミアムプラン（モック）を解放しました！'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
              ),
              child: const Text('モック購入を完了'),
            ),
        ],
      ),
    );
  }

  /// 購入復元（Restore）ボタン押下時のモック処理
  Future<void> _handleRestore(BuildContext context) async {
    setState(() => _isProcessing = true);
    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('購入履歴を確認しました（ストア決済連携は準備中です）。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

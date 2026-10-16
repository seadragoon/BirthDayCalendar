import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/theme/app_theme.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';

/// きせかえ（テーマ）選択画面。
///
/// カラー変更（標準テーマのプライマリカラー）と、プリセットきせかえ（桜、夜空）を選択できる。
class ThemeSelectionModal extends ConsumerWidget {
  const ThemeSelectionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeAsync = ref.watch(themeProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return currentThemeAsync.when(
      data: (currentTheme) => BaseModal(
        title: 'きせかえ（テーマ）',
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // カラー変更セクション
              _buildSectionHeader(context, 'カラー変更'),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: EventColor.values.map((ec) {
                      final isSelected = currentTheme.type == AppThemeType.standard && 
                                        currentTheme.primaryColor.toARGB32() == ec.color.toARGB32();
                      return GestureDetector(
                        onTap: () => ref.read(themeProvider.notifier).updatePrimaryColor(ec.color),
                        child: Container(
                          decoration: BoxDecoration(
                            color: ec.color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.black54, width: 3) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // きせかえテーマセクション
              _buildSectionHeader(context, 'プリセットテーマ'),
              const SizedBox(height: 16),
              _buildThemeOption(
                context: context,
                ref: ref,
                type: AppThemeType.sakura,
                label: '桜（サクラ）',
                description: '春の訪れを感じる華やかな和風ピンク',
                assetPath: 'assets/images/themes/sakura.png',
                currentType: currentTheme.type,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context: context,
                ref: ref,
                type: AppThemeType.night,
                label: '夜空（ナイト）',
                description: '静寂な星空が広がるディープインディゴ',
                assetPath: 'assets/images/themes/night.png',
                currentType: currentTheme.type,
              ),

              const SizedBox(height: 48),

              // ────────────── プレミアム機能（PRO）エリア ──────────────
              _buildPremiumSection(context, ref, currentTheme, isPremium),
              
              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    Icon(Icons.stars, color: Colors.amber.shade300, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'きせかえテーマは今後追加予定です',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      loading: () => const BaseModal(
        title: 'きせかえ（テーマ）',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => BaseModal(
        title: 'きせかえ（テーマ）',
        body: Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }

  /// プレミアム限定機能（テーマ＆写真きせかえ）を美しくグルーピングしてデザイン分離するコンテナ
  Widget _buildPremiumSection(
    BuildContext context, 
    WidgetRef ref, 
    AppThemeData currentTheme,
    bool isPremium,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerBg = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221C14), Color(0xFF181510)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFDF5), Color(0xFFFFF8E7)],
          );

    final borderColor = isDark
        ? Colors.amber.shade700.withValues(alpha: 0.5)
        : Colors.amber.shade300;

    final titleColor = isDark ? Colors.amber.shade300 : Colors.amber.shade900;

    return Container(
      decoration: BoxDecoration(
        gradient: containerBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.amber.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👑 プレミアムバナーヘッダー（未解放時はタップで案内モーダル表示）
          InkWell(
            onTap: !isPremium ? () => _showPremiumPromoModal(context) : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isPremium
                          ? const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPremium ? Icons.stars_rounded : Icons.workspace_premium,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isPremium ? 'プレミアム有効' : 'プレミアム機能',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPremium
                                    ? (isDark ? Colors.green.shade900.withValues(alpha: 0.6) : Colors.green.shade100)
                                    : (isDark ? Colors.amber.shade900.withValues(alpha: 0.6) : Colors.amber.shade100),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPremium
                                      ? (isDark ? Colors.green.shade600 : Colors.green.shade400)
                                      : (isDark ? Colors.amber.shade600 : Colors.amber.shade400),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isPremium ? 'PRO 会員' : 'PRO',
                                style: TextStyle(
                                  color: isPremium ? const Color(0xFF2E7D32) : const Color(0xFFFF8F00),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium
                              ? 'すべての限定テーマとオリジナル写真背景をご利用いただけます ✨'
                              : '特別な限定テーマや写真背景で、さらに華やかにカスタマイズ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPremium) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          Divider(color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade200),
          const SizedBox(height: 16),

          // 1. プレミアム限定テーマ
          _buildSectionHeader(
            context,
            'プレミアム限定テーマ',
            fontSize: 17,
            trailingBadge: _buildPremiumBadge(
              isPremium: isPremium,
              icon: Icons.stars,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? '洗練された世界観と専用パレットで彩る特別な限定テーマです。お好きなテーマを選んで適用できます。'
                : '洗練された世界観と専用パレットで彩る特別な限定テーマです（PRO限定）。',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildThemeOption(
            context: context,
            ref: ref,
            type: AppThemeType.mint,
            label: 'ミント（ボタニカル）',
            description: '爽やかな北欧風ハーブと木漏れ日',
            assetPath: 'assets/images/themes/mint.jpg',
            currentType: currentTheme.type,
            isPremium: true,
            hasPremiumAccess: isPremium,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context: context,
            ref: ref,
            type: AppThemeType.cafe,
            label: 'モカ（カフェ）',
            description: '温かみのあるラテとくすみベージュ',
            assetPath: 'assets/images/themes/cafe.jpg',
            currentType: currentTheme.type,
            isPremium: true,
            hasPremiumAccess: isPremium,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context: context,
            ref: ref,
            type: AppThemeType.sunset,
            label: '夕暮れ（サンセット）',
            description: '黄昏時のエモーショナルなグラデーション',
            assetPath: 'assets/images/themes/sunset.jpg',
            currentType: currentTheme.type,
            isPremium: true,
            hasPremiumAccess: isPremium,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context: context,
            ref: ref,
            type: AppThemeType.rose,
            label: 'ローズ（エレガント）',
            description: '大理石と上品なアンティークローズ',
            assetPath: 'assets/images/themes/rose.jpg',
            currentType: currentTheme.type,
            isPremium: true,
            hasPremiumAccess: isPremium,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context: context,
            ref: ref,
            type: AppThemeType.ocean,
            label: '海（オーシャン）',
            description: '透き通るエメラルドブルーの水面ときらめき',
            assetPath: 'assets/images/themes/ocean.jpg',
            currentType: currentTheme.type,
            isPremium: true,
            hasPremiumAccess: isPremium,
          ),

          const SizedBox(height: 36),

          // 2. オリジナル背景設定
          _buildSectionHeader(
            context,
            'オリジナル背景設定',
            fontSize: 17,
            trailingBadge: _buildPremiumBadge(
              isPremium: isPremium,
              icon: Icons.photo_library,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? '推し・お子さま・ペット・お気に入りの風景写真をカレンダーの背景に設定できます。'
                : '推し・お子さま・ペット・お気に入りの風景写真をカレンダーの背景に設定できます（PRO限定）。',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildCustomBackgroundSection(
            context, 
            ref, 
            currentTheme,
            hasPremiumAccess: isPremium,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge({required bool isPremium, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
              )
            : const LinearGradient(
                colors: [Color(0xFFFFA000), Color(0xFFE65100)],
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPremium ? icon : Icons.lock, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          const Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, 
    String title, {
    Widget? trailingBadge,
    double fontSize = 18,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  fontSize: fontSize, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              trailingBadge,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ],
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required AppThemeType type,
    required String label,
    required String assetPath,
    required AppThemeType currentType,
    String? description,
    bool isPremium = false,
    bool hasPremiumAccess = true,
  }) {
    final isSelected = currentType == type;
    final themeColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedCardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final selectedCardColor = isDark ? themeColor.withValues(alpha: 0.25) : themeColor.withValues(alpha: 0.08);
    final unselectedBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final selectedBorderColor = isDark ? themeColor.withValues(alpha: 0.8) : themeColor;
    final unselectedTextColor = isDark ? Colors.white70 : Colors.black87;
    // ダークモード時は、選択中の文字色も視認性のため少し明るめのテーマ色や白系にする
    final selectedTextColor = isDark ? Colors.white : themeColor;
    final checkIconColor = isDark ? Colors.white : themeColor;

    // プレミアムテーマでかつ未解放の場合
    final isLocked = isPremium && !hasPremiumAccess;

    return InkWell(
      onTap: () {
        if (isLocked) {
          _showPremiumPromoModal(context, featureTitle: '$label テーマ');
          return;
        }
        ref.read(themeProvider.notifier).setThemeType(type);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorderColor : unselectedBorderColor,
            width: 2.5,
          ),
          color: isSelected ? selectedCardColor : unselectedCardColor,
          boxShadow: isSelected ? [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : themeColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            // テーマプレビュー
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(assetPath, fit: BoxFit.cover),
                  ),
                ),
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label, 
                          style: TextStyle(
                            fontSize: 17, 
                            fontWeight: FontWeight.bold,
                            color: isSelected ? selectedTextColor : unselectedTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? (isDark ? Colors.amber.shade900.withValues(alpha: 0.5) : Colors.amber.shade100)
                                : (isDark ? Colors.amber.shade800.withValues(alpha: 0.5) : Colors.amber.shade100),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLocked ? Colors.amber.shade600 : Colors.amber.shade400,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLocked ? Icons.lock : Icons.stars, 
                                color: isLocked ? Colors.amber.shade900 : Colors.amber.shade800, 
                                size: 11,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '限定',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              Icon(Icons.check_circle, color: checkIconColor, size: 26)
            else if (isLocked)
              Icon(
                Icons.lock_outline, 
                color: isDark ? Colors.amber.shade300 : Colors.amber.shade700, 
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  /// 写真きせかえ（カスタム背景写真）の操作セクション
  Widget _buildCustomBackgroundSection(
    BuildContext context,
    WidgetRef ref,
    AppThemeData currentTheme, {
    required bool hasPremiumAccess,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = Theme.of(context).primaryColor;
    final hasCustomBg = currentTheme.customBackgroundPath != null;

    if (!hasCustomBg) {
      // 未設定時：写真選択ボタンカード
      return InkWell(
        onTap: () {
          if (!hasPremiumAccess) {
            _showPremiumPromoModal(context, featureTitle: 'オリジナル背景設定');
            return;
          }
          _pickAndSetImage(context, ref);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: !hasPremiumAccess
                  ? (isDark ? Colors.amber.shade700.withValues(alpha: 0.6) : Colors.amber.shade300)
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: 1.5,
            ),
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !hasPremiumAccess
                      ? Colors.amber.withValues(alpha: 0.15)
                      : themeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  !hasPremiumAccess ? Icons.lock_outline : Icons.add_photo_alternate_outlined,
                  color: !hasPremiumAccess ? Colors.amber.shade800 : themeColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'アルバムから写真を選ぶ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPremiumAccess
                    ? '好きな写真をカレンダー背景に設定'
                    : '好きな写真をカレンダー背景に設定 (PRO限定)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              if (!hasPremiumAccess) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'PROで解放する',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 設定済み時：プレビュー、スライダー、変更・削除ボタン
    final file = File(currentTheme.customBackgroundPath!);
    final opacityPercent = (currentTheme.backgroundOpacity * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.grey.shade800 : Colors.white,
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 写真プレビュー
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                        ),
                      ),
                      // 適用中のホワイトアウト/ブラックアウトを再現
                      Container(
                        color: (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: currentTheme.backgroundOpacity),
                      ),
                      Center(
                        child: Text(
                          'カレンダー背景プレビュー',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                            shadows: [
                              Shadow(
                                color: isDark ? Colors.black54 : Colors.white,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasPremiumAccess ? Icons.check_circle : Icons.lock, 
                        color: hasPremiumAccess ? Colors.greenAccent : Colors.amberAccent, 
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasPremiumAccess ? '設定中' : 'PRO限定設定',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 背景の濃さ調整スライダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '文字の見やすさ（背景の濃さ）',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                '$opacityPercent%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '薄く',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              Expanded(
                child: Slider(
                  value: currentTheme.backgroundOpacity,
                  min: 0.50,
                  max: 0.95,
                  divisions: 9,
                  label: '$opacityPercent%',
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).setBackgroundOpacity(val);
                  },
                ),
              ),
              Text(
                '濃く',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // アクションボタン（写真を変更 / 解除）
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (!hasPremiumAccess) {
                      _showPremiumPromoModal(context, featureTitle: 'オリジナル背景設定');
                      return;
                    }
                    _pickAndSetImage(context, ref);
                  },
                  icon: Icon(
                    !hasPremiumAccess ? Icons.lock_outline : Icons.photo_library_outlined, 
                    size: 18,
                  ),
                  label: Text(!hasPremiumAccess ? '写真を変更 (PRO限定)' : '写真を変更'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _confirmClearCustomBackground(context, ref),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                label: const Text('解除', style: TextStyle(color: Colors.redAccent)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// フォトライブラリから画像を選択して保存
  Future<void> _pickAndSetImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await ref.read(themeProvider.notifier).setCustomBackgroundImage(File(pickedFile.path));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('カレンダー背景写真に設定しました'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真の選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 背景写真の解除確認ダイアログ
  Future<void> _confirmClearCustomBackground(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('背景写真を解除'),
        content: const Text('設定中の写真を解除し、元のテーマ背景に戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('解除する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(themeProvider.notifier).clearCustomBackgroundImage();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('背景写真を解除しました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// プレミアム紹介モーダルを表示
  void _showPremiumPromoModal(BuildContext context, {String? featureTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PremiumPromoModalSheet(featureTitle: featureTitle),
    );
  }
}

/// プレミアム限定機能の案内ボトムシート
class _PremiumPromoModalSheet extends StatelessWidget {
  final String? featureTitle;

  const _PremiumPromoModalSheet({this.featureTitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24, 
        12, 
        24, 
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 王冠グラデーションアイコン
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),

          // タイトル
          Text(
            featureTitle != null ? 'プレミアム限定機能' : 'BirthDay Calendar プレミアム',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          // サブタイトル
          Text(
            featureTitle != null
                ? '「$featureTitle」を利用するにはプレミアムプランの解放が必要です。'
                : '特別なテーマや写真背景で、あなただけのカレンダーにカスタマイズ！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // 特典ハイライトリスト
          _buildFeatureTile(
            icon: Icons.palette_outlined,
            title: 'プレミアム限定テーマ 5種',
            subtitle: 'ミント・モカ・夕暮れ・ローズ・海が使い放題',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildFeatureTile(
            icon: Icons.photo_library_outlined,
            title: '写真きせかえ（オリジナル背景）',
            subtitle: '推しや家族、ペットの写真をカレンダー背景に設定',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildFeatureTile(
            icon: Icons.widgets_outlined,
            title: '写真付きカウントダウンウィジェット',
            subtitle: 'ホーム画面でいつでも大切な記念日と写真を確認',
            isDark: isDark,
          ),

          // 🛠️ デバッグ環境案内（kDebugMode専用）
          if (kDebugMode) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.amber.shade700 : Colors.amber.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bug_report, size: 20, color: Colors.amber.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '【開発テスト用】基本設定画面の一番下にある「プレミアム状態モック」をONにすると即座にお試しいただけます。',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ボタン
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                '閉じる',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.amber.shade800, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


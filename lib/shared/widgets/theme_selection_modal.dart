import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/theme/app_theme.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// きせかえ（テーマ）選択画面。
///
/// カラー変更（標準テーマのプライマリカラー）と、プリセットきせかえ（桜、夜空）を選択できる。
class ThemeSelectionModal extends ConsumerWidget {
  const ThemeSelectionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeAsync = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return currentThemeAsync.when(
      data: (currentTheme) => BaseModal(
        title: 'きせかえ（テーマ）',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
              _buildSectionHeader(context, 'きせかえテーマ'),
              const SizedBox(height: 16),
              _buildThemeOption(
                context: context,
                ref: ref,
                type: AppThemeType.sakura,
                label: '桜（サクラ）',
                assetPath: 'assets/images/themes/sakura.png',
                currentType: currentTheme.type,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context: context,
                ref: ref,
                type: AppThemeType.night,
                label: '夜空（ナイト）',
                assetPath: 'assets/images/themes/night.png',
                currentType: currentTheme.type,
              ),

              const SizedBox(height: 48),

              // 写真きせかえセクション（オリジナル背景）
              _buildSectionHeader(context, '写真きせかえ（オリジナル背景）'),
              const SizedBox(height: 8),
              Text(
                '推し・お子さま・ペット・お気に入りの風景写真をカレンダーの背景に設定できます。',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildCustomBackgroundSection(context, ref, currentTheme),
              
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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

    return InkWell(
      onTap: () => ref.read(themeProvider.notifier).setThemeType(type),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 90,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(assetPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label, 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: checkIconColor, size: 28),
          ],
        ),
      ),
    );
  }

  /// 写真きせかえ（カスタム背景写真）の操作セクション
  Widget _buildCustomBackgroundSection(
    BuildContext context,
    WidgetRef ref,
    AppThemeData currentTheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = Theme.of(context).primaryColor;
    final hasCustomBg = currentTheme.customBackgroundPath != null;

    if (!hasCustomBg) {
      // 未設定時：写真選択ボタンカード
      return InkWell(
        onTap: () => _pickAndSetImage(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.5,
            ),
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_photo_alternate_outlined, color: themeColor, size: 32),
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
                '好きな写真をカレンダー背景に設定',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '設定中',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                  onPressed: () => _pickAndSetImage(context, ref),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('写真を変更'),
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
}


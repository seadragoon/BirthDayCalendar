import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

              const SizedBox(height: 48),

              // きせかえセクション
              _buildSectionHeader(context, 'きせかえ'),
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
}

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
    final currentTheme = ref.watch(themeProvider);

    return BaseModal(
      title: 'きせかえ（テーマ）',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カラー変更セクション
            _buildSectionHeader('カラー変更'),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: EventColor.values.map((ec) {
                  final isSelected = currentTheme.type == AppThemeType.standard && 
                                    currentTheme.primaryColor == ec.color;
                  return GestureDetector(
                    onTap: () => ref.read(themeProvider.notifier).updatePrimaryColor(ec.color),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: ec.color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black54, width: 3) : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 28) : null,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 48),

            // きせかえセクション
            _buildSectionHeader('きせかえ'),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade200),
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

    return InkWell(
      onTap: () => ref.read(themeProvider.notifier).setThemeType(type),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey.shade200,
            width: 2.5,
          ),
          color: isSelected ? themeColor.withValues(alpha: 0.08) : Colors.white,
          boxShadow: isSelected ? [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.1),
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
                  color: isSelected ? themeColor : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: themeColor, size: 28),
          ],
        ),
      ),
    );
  }
}

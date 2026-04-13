import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/shared/theme/app_theme.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';

/// アプリのドロワー（サイドメニュー）。
///
/// 現在は「きせかえ（テーマ）」変更の設定メニューとして使用。
class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: currentTheme.primaryColor,
              image: currentTheme.backgroundImagePath.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(currentTheme.backgroundImagePath),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.2),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Text(
              '設定メニュー',
              style: TextStyle(
                color: currentTheme.onPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('きせかえ（テーマ）', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...AppThemeData.values.map((theme) {
            final isSelected = theme.type == currentTheme.type;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? currentTheme.primaryColor : Colors.grey,
              ),
              title: Text(theme.label),
              onTap: () {
                ref.read(themeProvider.notifier).setTheme(theme);
                Navigator.of(context).pop(); // ドロワーを閉じる
              },
            );
          }),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('その他', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('アプリについて'),
            onTap: () {
              Navigator.of(context).pop(); // まずドロワーを閉じる
              showAboutDialog(
                context: context,
                applicationName: 'Birthday Calendar',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Developer',
                children: const [
                  SizedBox(height: 16),
                  Text('大切な人の誕生日や日常のスケジュールを管理するシンプルなカレンダーアプリです。'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

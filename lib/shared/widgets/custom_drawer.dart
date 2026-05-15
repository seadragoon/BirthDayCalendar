import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/widgets/theme_selection_modal.dart';
import 'package:birthday_calendar/features/birthday/views/tag_management_view.dart';
import 'package:birthday_calendar/features/settings/widgets/birthday_display_settings_modal.dart';
import 'package:birthday_calendar/features/settings/widgets/basic_settings_modal.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/features/settings/widgets/theme_mode_dialog.dart';

/// アプリのドロワー（サイドメニュー）。
///
/// 現在は「きせかえ（テーマ）」変更の設定メニューとして使用。
class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider).requireValue;
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final themeMode = appSettingsAsync.valueOrNull?.themeMode ?? 1;

    IconData getThemeModeIcon() {
      switch (themeMode) {
        case 0:
          return Icons.brightness_auto;
        case 1:
          return Icons.light_mode;
        case 2:
          return Icons.dark_mode;
        default:
          return Icons.light_mode;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onPrimaryColor = isDark ? currentTheme.darkOnPrimaryColor : currentTheme.onPrimaryColor;

    return Drawer(
      child: Column(
        children: [
          Expanded(
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
                color: onPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('アプリ設定', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('基本設定'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BasicSettingsModal(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('きせかえ（テーマ）'),
            onTap: () {
              Navigator.of(context).pop(); // ドロワーを閉じる
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ThemeSelectionModal(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('誕生日', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('タグ管理'),
            onTap: () {
              Navigator.of(context).pop(); // まずドロワーを閉じる
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TagManagementView(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_month_outlined),
            title: const Text('表示設定'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BirthdayDisplaySettingsModal(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
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
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(getThemeModeIcon()),
                    tooltip: 'ダークモード設定',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ThemeModeDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

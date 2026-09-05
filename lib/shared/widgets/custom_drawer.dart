import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/widgets/theme_selection_modal.dart';
import 'package:birthday_calendar/features/birthday/views/tag_management_view.dart';
import 'package:birthday_calendar/features/settings/widgets/birthday_display_settings_modal.dart';
import 'package:birthday_calendar/features/settings/widgets/basic_settings_modal.dart';
import 'package:birthday_calendar/features/settings/widgets/calendar_settings_modal.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/features/settings/widgets/theme_mode_dialog.dart';
import 'package:birthday_calendar/features/backup/views/backup_restore_modal.dart';
import 'package:birthday_calendar/features/birthday/widgets/contact_import_modal.dart';

/// アプリのドロワー（サイドメニュー）。
///
/// 設定、カレンダー、誕生日、データ管理、Aboutなどの各画面へ遷移する。
/// スクロール可能であることが一目でわかるよう、常時スクロールバーと
/// 下端フェードインジケーターを備える。
class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canScroll = maxScroll > 0 && currentScroll < maxScroll - 8;
    if (_canScrollDown != canScroll) {
      setState(() {
        _canScrollDown = canScroll;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final drawerBgColor = Theme.of(context).drawerTheme.backgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true, // 常にスクロールバーを表示してアフォーダンスを向上
                  radius: const Radius.circular(4),
                  thickness: 4,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // スリム化したヘッダー（下部項目のチラ見せを促進）
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        alignment: Alignment.bottomLeft,
                        constraints: const BoxConstraints(minHeight: 110),
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
                        child: SafeArea(
                          bottom: false,
                          child: Text(
                            '設定メニュー',
                            style: TextStyle(
                              color: onPrimaryColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // 1. アプリ設定
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text('アプリ設定', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('基本設定'),
            subtitle: const Text('通知のON/OFF', style: TextStyle(fontSize: 12)),
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
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ThemeSelectionModal(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const Divider(),

          // 2. カレンダー
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('カレンダー', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('カレンダー設定'),
            subtitle: const Text('週の開始日', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CalendarSettingsModal(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('誕生日の表示設定'),
            subtitle: const Text('カレンダー上の帯表示・色', style: TextStyle(fontSize: 12)),
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

          // 3. 誕生日
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('誕生日', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('タグ管理'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TagManagementView(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contacts_outlined),
            title: const Text('誕生日を取り込み'),
            subtitle: const Text('端末の連絡先から一括追加', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ContactImportModal(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const Divider(),

          // 4. データ連携・バックアップ
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('データ連携・バックアップ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('バックアップと復元'),
            subtitle: const Text('完全復元・.icsエクスポート', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BackupRestoreModal(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const Divider(),

          // 5. その他
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('その他', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('アプリについて'),
            onTap: () {
              Navigator.of(context).pop();
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
          const SizedBox(height: 16),
        ],
      ),
    ),
            // 下部にまだスクロールできる場合、うっすらグラデーションフェードと下矢印を表示
            if (_canScrollDown)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 28,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          drawerBgColor.withValues(alpha: 0.0),
                          drawerBgColor.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
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

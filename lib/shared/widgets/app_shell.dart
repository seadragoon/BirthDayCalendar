import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/birthday/views/birthday_view.dart';
import 'package:birthday_calendar/features/calendar/views/schedule_view.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/services/notification_service.dart';
import 'package:birthday_calendar/shared/widgets/custom_drawer.dart';
import 'package:birthday_calendar/shared/widgets/custom_fab.dart';
import 'package:birthday_calendar/shared/widgets/custom_footer.dart';
import 'package:birthday_calendar/shared/widgets/custom_header.dart';

/// アプリケーションのメインとなるScaffoldを提供するWidget。
///
/// Header (AppBar), Footer (NavigationBar), FAB, Drawer を統合し、
/// [viewTypeProvider] に応じてメインボディを切り替える。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialNotificationPermission();
    });
  }

  /// 初回起動時の通知権限確認ダイアログ
  Future<void> _checkInitialNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool('has_prompted_notification_permission') ?? false;
    if (hasPrompted) return;

    // 端末ですでに通知許可されている場合はダイアログを出さずに完了
    final alreadyGranted = await NotificationService.instance.areNotificationsGranted();
    if (alreadyGranted) {
      await prefs.setBool('has_prompted_notification_permission', true);
      return;
    }

    if (!mounted) return;

    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '通知を有効にしますか？',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            '予定や誕生日のリマインダー通知をタイムリーに受け取ることができます。\n通知を有効にしますか？',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('今はしない'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('通知をONにする'),
            ),
          ],
        );
      },
    );

    // 選択結果に関わらず、確認フラグを記録（次回以降は聞かない）
    await prefs.setBool('has_prompted_notification_permission', true);

    if (shouldEnable == true) {
      await ref.read(appSettingsProvider.notifier).setNotificationsEnabled(true);
      await NotificationService.instance.requestPermissions();
    } else {
      await ref.read(appSettingsProvider.notifier).setNotificationsEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewType = ref.watch(viewTypeProvider);
    final appTheme = ref.watch(themeProvider).requireValue;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox.expand(
      child: Scaffold(
        appBar: const CustomHeader(),
        drawer: const CustomDrawer(),
        body: Container(
          color: isDark ? appTheme.darkSurfaceColor : appTheme.surfaceColor,
          child: SafeArea(
            child: _buildBody(viewType),
          ),
        ),
        bottomNavigationBar: const CustomFooter(),
        floatingActionButton: const CustomFab(),
      ),
    );
  }

  /// 現在の [ViewType] に対応するViewを返す。
  Widget _buildBody(ViewType viewType) {
    switch (viewType) {
      case ViewType.schedule:
        return const ScheduleView();
      case ViewType.birthday:
        return const BirthdayView();
    }
  }
}

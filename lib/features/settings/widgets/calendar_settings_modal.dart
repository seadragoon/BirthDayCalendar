import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';
import 'package:birthday_calendar/shared/widgets/multi_select_dialog.dart';

/// カレンダーに関する表示・動作設定画面。
class CalendarSettingsModal extends ConsumerWidget {
  const CalendarSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingsAsync = ref.watch(appSettingsProvider);

    return BaseModal(
      title: 'カレンダー設定',
      body: appSettingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '表示設定',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('週の開始日'),
              subtitle: Text(settings.firstDayOfWeek == 0 ? '日曜日' : '月曜日'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showFirstDayOfWeekDialog(context, ref, settings.firstDayOfWeek),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: const Text('六曜を表示'),
              subtitle: const Text('大安・友引・仏滅などの暦注を表示します'),
              value: settings.showRokuyo,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setShowRokuyo(value);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '予定登録の初期設定',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.access_time_outlined),
              title: const Text('終日をデフォルトにする'),
              subtitle: const Text('新規予定の作成時に終日を最初からONにします'),
              value: settings.defaultIsAllDay,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setDefaultIsAllDay(value);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: EventColor.fromIndex(settings.defaultColorIndex).color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              title: const Text('デフォルトの予定カラー'),
              subtitle: Text(EventColor.fromIndex(settings.defaultColorIndex).label),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showDefaultColorDialog(context, ref, settings.defaultColorIndex),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('デフォルトの通知タイミング'),
              subtitle: Text(
                settings.defaultNotifications.isEmpty ||
                        (settings.defaultNotifications.length == 1 &&
                            settings.defaultNotifications.first == NotificationType.none)
                    ? 'なし'
                    : settings.defaultNotifications.map((e) => e.label).join(', '),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showDefaultNotificationsDialog(context, ref, settings.defaultNotifications),
            ),
            const Divider(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }

  Future<void> _showDefaultColorDialog(
    BuildContext context,
    WidgetRef ref,
    int currentColorIndex,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('デフォルトカラーを選択', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: EventColor.values.map((color) {
                final isSelected = color.index == currentColorIndex;
                return InkWell(
                  onTap: () {
                    ref.read(appSettingsProvider.notifier).setDefaultColorIndex(color.index);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.15),
                          blurRadius: isSelected ? 6 : 3,
                          spreadRadius: isSelected ? 1 : 0,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDefaultNotificationsDialog(
    BuildContext context,
    WidgetRef ref,
    List<NotificationType> currentNotifications,
  ) async {
    final result = await showDialog<List<NotificationType>>(
      context: context,
      builder: (context) {
        return MultiSelectDialog<NotificationType>(
          items: NotificationType.values,
          initialSelectedItems: currentNotifications,
          title: 'デフォルト通知設定',
          labelBuilder: (item) => item.label,
          noneItem: NotificationType.none,
        );
      },
    );

    if (result != null) {
      ref.read(appSettingsProvider.notifier).setDefaultNotifications(result);
    }
  }

  Future<void> _showFirstDayOfWeekDialog(
    BuildContext context,
    WidgetRef ref,
    int currentValue,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('週の開始日を選択', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('日曜日'),
                trailing: currentValue == 0 ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setFirstDayOfWeek(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('月曜日'),
                trailing: currentValue == 1 ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setFirstDayOfWeek(1);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }
}

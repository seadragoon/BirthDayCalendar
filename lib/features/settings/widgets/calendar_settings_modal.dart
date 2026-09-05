import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

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
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラーが発生しました: $e')),
      ),
    );
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

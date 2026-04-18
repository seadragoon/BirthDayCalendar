import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// アプリ全体の基本設定画面。
class BasicSettingsModal extends ConsumerWidget {
  const BasicSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingsAsync = ref.watch(appSettingsProvider);

    return BaseModal(
      title: '基本設定',
      body: appSettingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 通知設定
            _buildSectionHeader('通知'),
            SwitchListTile(
              title: const Text('通知を有効にする'),
              subtitle: const Text('誕生日や予定のお知らせを受け取ります'),
              value: settings.isNotificationsEnabled,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setNotificationsEnabled(value);
              },
            ),
            const Divider(),

            // カレンダー設定
            const SizedBox(height: 16),
            _buildSectionHeader('カレンダー'),
            ListTile(
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
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
          title: const Text('週の開始日を選択'),
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

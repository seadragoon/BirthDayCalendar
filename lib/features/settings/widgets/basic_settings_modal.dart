import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';
import 'package:birthday_calendar/shared/services/notification_service.dart';

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
              onChanged: (value) async {
                if (value) {
                  // 端末側で通知が許可されているか確認
                  final isGranted = await NotificationService.instance.areNotificationsGranted();
                  if (!isGranted) {
                    if (!context.mounted) return;
                    final shouldOpenSettings = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.notifications_off_outlined, color: Colors.orange, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '通知が許可されていません',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          content: const Text(
                            '予定や誕生日の通知を受け取るには、端末の設定で通知を許可する必要があります。\n設定画面を開きますか？',
                            style: TextStyle(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              child: const Text('設定を開く'),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldOpenSettings == true) {
                      await NotificationService.instance.requestPermissions();
                      await ref.read(appSettingsProvider.notifier).setNotificationsEnabled(true);
                    }
                    return;
                  }
                }
                await ref.read(appSettingsProvider.notifier).setNotificationsEnabled(value);
              },
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
}

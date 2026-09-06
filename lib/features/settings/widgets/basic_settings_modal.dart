import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';
import 'package:birthday_calendar/shared/services/notification_service.dart';
import 'package:birthday_calendar/features/widget/services/widget_sync_service.dart';
import 'package:birthday_calendar/features/security/providers/security_providers.dart';
import 'package:birthday_calendar/features/security/widgets/security_settings_modal.dart';

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

            // セキュリティ設定
            _buildSectionHeader('セキュリティ'),
            Builder(
              builder: (context) {
                final securitySettings = ref.watch(securitySettingsProvider).valueOrNull;
                final isSecured = securitySettings?.hasValidPasscode ?? false;

                return ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('パスコード・生体認証ロック'),
                  subtitle: Text(
                    isSecured ? '有効（保護中）' : '未設定（無効）',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSecured ? Colors.green : Colors.grey,
                      fontWeight: isSecured ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SecuritySettingsModal(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),

            // ホーム画面ウィジェット
            _buildSectionHeader('ホーム画面ウィジェット'),
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: const Text('ウィジェットのデータを手動更新'),
              subtitle: const Text('ホーム画面の「もうすぐ誕生日」を最新化します', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.sync, size: 20),
              onTap: () async {
                await WidgetSyncService.updateWidgetData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ウィジェットのデータを最新状態に更新しました。'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).hintColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ホーム画面の何もない場所を長押しし、「ウィジェット」から「BirthDay Calendar」を選択して追加してください。',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
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

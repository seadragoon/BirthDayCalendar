import 'package:flutter/material.dart';
import 'package:birthday_calendar/features/legal/services/contact_service.dart';
import 'package:birthday_calendar/shared/constants/app_constants.dart';

/// お問い合わせ・ご意見案内ダイアログ
class ContactDialog extends StatelessWidget {
  const ContactDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.mail_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('お問い合わせ・ご意見', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アプリの不具合報告、機能のご要望、その他ご意見がございましたら、以下のサポート窓口までお気軽にお寄せください。',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'サポート窓口（メール）',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  AppConstants.supportEmail,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '※ メーラー起動時、OSやアプリのバージョン情報が自動的にメール本文の雛形に挿入されます。',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await ContactService.copySupportEmail();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('サポートアドレスをコピーしました'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('アドレスをコピー'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final launched = await ContactService.launchEmail();
            if (launched) {
              navigator.pop();
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('メールアプリを起動できませんでした。アドレスをコピーして直接お送りください。'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('メールを作成'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';

/// ダークモードの切り替えを行うダイアログ
class ThemeModeDialog extends ConsumerWidget {
  const ThemeModeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final themeMode = appSettingsAsync.valueOrNull?.themeMode ?? 1;

    return AlertDialog(
      title: const Text('ダークモード設定'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('オフ（ライト）'),
            trailing: themeMode == 1 ? const Icon(Icons.check) : null,
            onTap: () {
              ref.read(appSettingsProvider.notifier).setThemeMode(1);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('オン（ダーク）'),
            trailing: themeMode == 2 ? const Icon(Icons.check) : null,
            onTap: () {
              ref.read(appSettingsProvider.notifier).setThemeMode(2);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('端末の設定を使う'),
            trailing: themeMode == 0 ? const Icon(Icons.check) : null,
            onTap: () {
              ref.read(appSettingsProvider.notifier).setThemeMode(0);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}

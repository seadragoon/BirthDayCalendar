import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';

/// タグの一覧管理画面。
///
/// タグの追加・削除が可能。
class TagManagementView extends ConsumerWidget {
  const TagManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagListAsync = ref.watch(tagListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('タグ管理', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTagDialog(context, ref),
          ),
        ],
      ),
      body: tagListAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(
              child: Text('タグが登録されていません', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            itemCount: tags.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tag = tags[index];
              return ListTile(
                title: Text(tag.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteConfirmDialog(context, ref, tag.id!, tag.name),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }

  /// タグ追加ダイアログを表示
  Future<void> _showAddTagDialog(BuildContext context, WidgetRef ref) async {
    String newTagName = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タグを追加'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'タグ名を入力'),
            onChanged: (value) => newTagName = value.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                if (newTagName.isEmpty) {
                  Navigator.pop(context);
                  return;
                }

                // 重複チェック
                final tagList = ref.read(tagListProvider).valueOrNull ?? [];
                if (tagList.any((t) => t.name == newTagName)) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('注意'),
                      content: const Text('既に追加済みのタグです'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                await ref.read(tagListProvider.notifier).addTag(newTagName);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  /// タグ削除確認ダイアログを表示
  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    int tagId,
    String tagName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タグの削除'),
          content: Text('「$tagName」を削除しますか？\n(既にそのタグが設定されている誕生日データからは削除されません)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(tagListProvider.notifier).deleteTag(tagId);
    }
  }
}

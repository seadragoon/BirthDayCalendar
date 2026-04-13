import 'package:flutter/material.dart';

/// 全画面モーダルの共通ベースレイアウト。
///
/// 下からスライドアップするモーダル（ `showGeneralDialog` または
/// `Navigator.push(..., fullscreenDialog: true)` など）で使用する。
/// ヘッダーに閉じるボタン、タイトル、アクション（保存、削除など）を持つ。
class BaseModal extends StatelessWidget {
  /// モーダルのタイトル
  final String title;

  /// メインの入力フォーム要素など
  final Widget body;

  /// 保存ボタンのコールバック。nullの場合は保存ボタンを非表示にする
  final VoidCallback? onSave;

  /// 保存ボタンが有効かどうか（バリデーション用）
  final bool isSaveActionEnabled;

  /// 削除ボタンのコールバック。nullの場合は削除ボタンを非表示にする
  final VoidCallback? onDelete;

  /// 編集モードかどうか（削除ボタンなどの表示判定に利用）
  final bool isEditMode;

  const BaseModal({
    super.key,
    required this.title,
    required this.body,
    this.onSave,
    this.isSaveActionEnabled = true,
    this.onDelete,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '閉じる',
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isEditMode && onDelete != null)
            IconButton(
              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              tooltip: '削除',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('確認'),
                    content: const Text('本当に削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('削除'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  onDelete!();
                }
              },
            ),
          if (onSave != null)
            TextButton(
              onPressed: isSaveActionEnabled ? onSave : null,
              child: const Text(
                '保存',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: body,
      ),
    );
  }
}

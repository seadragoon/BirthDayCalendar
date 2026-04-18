import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/shared/providers/theme_provider.dart';

/// 全画面モーダルの共通ベースレイアウト。
///
/// 下からスライドアップするモーダル（ `showGeneralDialog` または
/// `Navigator.push(..., fullscreenDialog: true)` など）で使用する。
/// ヘッダーに閉じるボタン、タイトル、アクション（保存、削除など）を持つ。
class BaseModal extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider).requireValue;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundImagePath.isEmpty ? appTheme.primaryColor : null,
            image: appTheme.backgroundImagePath.isNotEmpty
                ? DecorationImage(
                    image: AssetImage(appTheme.backgroundImagePath),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
        ),
        iconTheme: IconThemeData(color: appTheme.onPrimaryColor),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '閉じる',
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: appTheme.onPrimaryColor,
          ),
        ),
        actions: [
          if (isEditMode && onDelete != null)
            IconButton(
              icon: Icon(Icons.delete, color: appTheme.onPrimaryColor.withValues(alpha: 0.8)),
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
              child: Text(
                '保存',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSaveActionEnabled ? appTheme.onPrimaryColor : appTheme.onPrimaryColor.withValues(alpha: 0.5),
                ),
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

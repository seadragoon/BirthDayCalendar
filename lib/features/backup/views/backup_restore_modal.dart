import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/backup/models/backup_data.dart';
import 'package:birthday_calendar/features/backup/services/backup_service.dart';
import 'package:birthday_calendar/features/backup/services/icalendar_service.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// バックアップと復元の操作画面モーダル。
class BackupRestoreModal extends ConsumerStatefulWidget {
  const BackupRestoreModal({super.key});

  @override
  ConsumerState<BackupRestoreModal> createState() => _BackupRestoreModalState();
}

class _BackupRestoreModalState extends ConsumerState<BackupRestoreModal> {
  DateTime? _lastBackupDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  Future<void> _loadLastBackupDate() async {
    final date = await BackupService.getLastBackupDate();
    if (mounted) {
      setState(() {
        _lastBackupDate = date;
      });
    }
  }

  /// バックアップの作成と共有
  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    try {
      await BackupService.exportBackup(context: context);
      await _loadLastBackupDate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップファイルを作成しました。保存先を選択してください。'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップ作成に失敗しました: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 他カレンダー向け (.ics) エクスポート
  Future<void> _handleExportIcs() async {
    setState(() => _isLoading = true);
    try {
      await ICalendarService.exportIcs(context: context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カレンダーファイル (.ics) を作成しました。保存先または共有先を選択してください。'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カレンダーファイルの作成に失敗しました: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// バックアップファイルの選択と復元確認ダイアログの表示
  Future<void> _handleImport() async {
    setState(() => _isLoading = true);
    try {
      final backupData = await BackupService.pickBackupFile();
      if (backupData == null) {
        // キャンセルされた場合
        return;
      }

      if (!mounted) return;
      await _showRestoreConfirmDialog(backupData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ファイルの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 復元確認＆モード選択ダイアログ
  Future<void> _showRestoreConfirmDialog(BackupData data) async {
    final dateFormat = DateFormat('yyyy年M月d日 HH:mm');
    bool overwrite = true; // デフォルトは上書き

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.restore_page_outlined, color: Colors.blue, size: 28),
                  SizedBox(width: 8),
                  Text('データの復元', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('作成日時: ${dateFormat.format(data.exportedAt)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('• 予定: ${data.events.length} 件'),
                          Text('• 誕生日: ${data.birthdays.length} 件'),
                          Text('• タグ: ${data.tags.length} 件'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('復元方法を選択してください:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioGroup<bool>(
                      groupValue: overwrite,
                      onChanged: (val) => setDialogState(() => overwrite = val ?? true),
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('上書き復元（推奨）'),
                            subtitle: const Text('現在の全データを消去し、バックアップの内容で置き換えます（機種変更時に推奨）'),
                            value: true,
                          ),
                          RadioListTile<bool>(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('追加復元'),
                            subtitle: const Text('現在のデータを保持したまま、重複しないデータのみを追加します'),
                            value: false,
                          ),
                        ],
                      ),
                    ),
                    if (overwrite) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '※ 現在登録されているデータはすべて削除されます。',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  style: overwrite
                      ? FilledButton.styleFrom(backgroundColor: Colors.red)
                      : null,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(overwrite ? '上書きして復元' : '追加復元'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      await _executeRestore(data, overwrite);
    }
  }

  /// 復元処理の実行
  Future<void> _executeRestore(BackupData data, bool overwrite) async {
    setState(() => _isLoading = true);
    try {
      final result = await BackupService.restoreBackup(
        data: data,
        overwrite: overwrite,
      );

      // Riverpod Providerの更新
      ref.invalidate(eventsByMonthProvider);
      ref.invalidate(eventsByDateProvider);
      ref.invalidate(birthdayListProvider);
      ref.invalidate(tagListProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('復元完了'),
              ],
            ),
            content: Text(
              'データの復元が完了しました。\n\n'
              '• 復元した予定: ${result.eventsCount} 件\n'
              '• 復元した誕生日: ${result.birthdaysCount} 件\n'
              '• 復元したタグ: ${result.tagsCount} 件',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元に失敗しました: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return BaseModal(
      title: 'バックアップと復元',
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ガイドカード
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '本アプリのデータはお使いの端末内に保存されています。端末の故障や機種変更に備えて、定期的にバックアップを保存することをおすすめします。',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // セクション1: バックアップ
              const Text(
                'バックアップ（データ出力）',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '最終バックアップ: ${_lastBackupDate != null ? dateFormat.format(_lastBackupDate!) : '未作成'}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '用途に合わせて書き出し形式を選択してください。',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      // オプション1: 完全バックアップ (JSON)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _handleExport,
                          icon: const Icon(Icons.backup_outlined),
                          label: const Text('完全バックアップを作成 (JSON)'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '※ 機種変更やアプリの完全復元用です。すべてのタグ・スタンプ・設定が含まれます。',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      // オプション2: 他カレンダー連携用 (.ics)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleExportIcs,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: const Text('他カレンダー用に出力 (.ics)'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '※ Googleカレンダー、Yahoo!カレンダー、iPhone標準カレンダー等に取り込める世界標準形式です。',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // セクション2: 復元
              const Text(
                '復元（データ取り込み）',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '過去に保存したバックアップ（.jsonファイル）を選択して、データをアプリ内に復元します。',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleImport,
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('バックアップファイルから復元'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

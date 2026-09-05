import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/birthday/models/contact_birthday_entry.dart';
import 'package:birthday_calendar/features/birthday/services/contact_import_service.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// 端末の連絡先から誕生日を選択して一括インポートするモーダル画面。
class ContactImportModal extends ConsumerStatefulWidget {
  const ContactImportModal({super.key});

  @override
  ConsumerState<ContactImportModal> createState() => _ContactImportModalState();
}

class _ContactImportModalState extends ConsumerState<ContactImportModal> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ContactBirthdayEntry> _contacts = [];
  String _searchQuery = '';
  final Set<String> _selectedTags = {};
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ContactImportService.fetchBirthdayContacts();
      if (mounted) {
        setState(() {
          _contacts = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<ContactBirthdayEntry> get _filteredContacts {
    if (_searchQuery.trim().isEmpty) return _contacts;
    final query = _searchQuery.trim().toLowerCase();
    return _contacts.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  int get _selectedCount => _contacts.where((c) => c.isSelected).length;

  void _toggleSelectAll(bool select) {
    setState(() {
      final currentList = _filteredContacts;
      for (final contact in currentList) {
        contact.isSelected = select;
      }
    });
  }

  Future<void> _handleImport() async {
    final selectedCount = _selectedCount;
    if (selectedCount == 0) return;

    setState(() => _isImporting = true);
    try {
      final count = await ContactImportService.importContacts(
        entries: _contacts,
        tags: _selectedTags.toList(),
      );

      // Provider の再読み込み
      ref.invalidate(birthdayListProvider);
      ref.invalidate(eventsByMonthProvider);
      ref.invalidate(eventsByDateProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count 件の誕生日を取り込みました。'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取り込み中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagListAsync = ref.watch(tagListProvider);
    final availableTags = tagListAsync.valueOrNull ?? [];

    return BaseModal(
      title: '連絡先から取り込み',
      body: _buildBody(theme, availableTags),
    );
  }

  Widget _buildBody(ThemeData theme, List<dynamic> availableTags) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('連絡先から誕生日を検索中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadContacts,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行する'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cake_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '誕生日が設定されている連絡先が\n見つかりませんでした。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'スマホの「連絡帳」アプリで連絡先に誕生日を登録してから再度お試しください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadContacts,
                icon: const Icon(Icons.refresh),
                label: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredContacts;

    return Column(
      children: [
        // 検索バー
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: '名前で検索...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // タグ選択バー
        if (availableTags.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                const Text('付与タグ:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableTags.map((tag) {
                        final tagName = tag.name as String;
                        final isSelected = _selectedTags.contains(tagName);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(tagName, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tagName);
                                } else {
                                  _selectedTags.remove(tagName);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 操作バー（全選択 / 全解除 / 選択件数）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Text(
                '$_selectedCount / ${_contacts.length} 件選択中',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _toggleSelectAll(true),
                child: const Text('すべて選択', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _toggleSelectAll(false),
                child: const Text('解除', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 連絡先リスト
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
            itemBuilder: (context, index) {
              final entry = filtered[index];
              final dateFormat = entry.isYearUnknown
                  ? DateFormat('M月d日 (年不明)')
                  : DateFormat('yyyy年M月d日');

              return CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                value: entry.isSelected,
                onChanged: (val) {
                  setState(() {
                    entry.isSelected = val ?? false;
                  });
                },
                secondary: CircleAvatar(
                  backgroundColor: entry.isAlreadyRegistered
                      ? Colors.grey.withValues(alpha: 0.3)
                      : theme.colorScheme.primaryContainer,
                  child: Text(
                    entry.name.isNotEmpty ? entry.name.characters.first : '?',
                    style: TextStyle(
                      color: entry.isAlreadyRegistered
                          ? Colors.grey
                          : theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: entry.isAlreadyRegistered ? Colors.grey : null,
                        ),
                      ),
                    ),
                    if (entry.isAlreadyRegistered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '登録済み',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  dateFormat.format(entry.birthday),
                  style: TextStyle(
                    fontSize: 13,
                    color: entry.isAlreadyRegistered ? Colors.grey : null,
                  ),
                ),
              );
            },
          ),
        ),

        // 下部ボタン
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _selectedCount == 0 || _isImporting ? null : _handleImport,
                child: _isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        '$_selectedCount 件の誕生日を取り込む',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

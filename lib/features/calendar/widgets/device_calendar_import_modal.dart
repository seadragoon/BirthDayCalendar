import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:file_picker/file_picker.dart';

import 'package:birthday_calendar/features/calendar/models/device_calendar_entry.dart';
import 'package:birthday_calendar/features/calendar/services/device_calendar_service.dart';
import 'package:birthday_calendar/features/backup/services/icalendar_service.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// 端末カレンダー（Googleカレンダー/iCloudカレンダー等）および.icsファイルから
/// 予定を選択して一括インポートするモーダル画面。
class DeviceCalendarImportModal extends ConsumerStatefulWidget {
  const DeviceCalendarImportModal({super.key});

  @override
  ConsumerState<DeviceCalendarImportModal> createState() => _DeviceCalendarImportModalState();
}

enum _DateRangeOption {
  oneMonthBackThreeMonthsAhead('前後（過去1ヶ月〜未来3ヶ月）', 30, 90),
  threeMonthsBackSixMonthsAhead('標準（過去3ヶ月〜未来6ヶ月）', 90, 180),
  oneYearBackOneYearAhead('広範囲（過去1年〜未来1年）', 365, 365),
  custom('期間を直接指定', 0, 0);

  final String label;
  final int daysBefore;
  final int daysAfter;

  const _DateRangeOption(this.label, this.daysBefore, this.daysAfter);
}

class _DeviceCalendarImportModalState extends ConsumerState<DeviceCalendarImportModal> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dc.Calendar> _calendars = [];
  String? _selectedCalendarId; // 'ics_file' はファイル取り込み用識別子
  
  _DateRangeOption _dateRangeOption = _DateRangeOption.threeMonthsBackSixMonthsAhead;
  late DateTime _startDate;
  late DateTime _endDate;

  List<DeviceCalendarEntry> _entries = [];
  String _searchQuery = '';
  EventColor _selectedColor = EventColor.lavender;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _applyDateRangeOption(_dateRangeOption);
    _initializeCalendars();
  }

  void _applyDateRangeOption(_DateRangeOption option) {
    _dateRangeOption = option;
    final now = DateTime.now();
    if (option != _DateRangeOption.custom) {
      _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: option.daysBefore));
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).add(Duration(days: option.daysAfter));
    }
  }

  Future<void> _initializeCalendars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final calendars = await DeviceCalendarService.getCalendars();
      if (!mounted) return;

      setState(() {
        _calendars = calendars;
        _isLoading = false;
        if (calendars.isNotEmpty) {
          // デフォルトカレンダー（primary）または先頭を選択
          final primary = calendars.firstWhere((c) => c.isDefault ?? false, orElse: () => calendars.first);
          _selectedCalendarId = primary.id;
        } else {
          _selectedCalendarId = 'ics_file';
        }
      });

      if (_selectedCalendarId != null && _selectedCalendarId != 'ics_file') {
        await _fetchEvents();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _fetchEvents() async {
    if (_selectedCalendarId == null || _selectedCalendarId == 'ics_file') return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await DeviceCalendarService.fetchEvents(
        calendarId: _selectedCalendarId!,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _entries = results;
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

  Future<void> _pickIcsFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _selectedCalendarId = 'ics_file';
        });

        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final entries = await ICalendarService.parseIcsToEntries(content);

        if (mounted) {
          setState(() {
            _entries = entries;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ファイルの読み込みに失敗しました: $e';
        });
      }
    }
  }

  List<DeviceCalendarEntry> get _filteredEntries {
    if (_searchQuery.trim().isEmpty) return _entries;
    final q = _searchQuery.trim().toLowerCase();
    return _entries.where((e) {
      return e.title.toLowerCase().contains(q) ||
          (e.description != null && e.description!.toLowerCase().contains(q));
    }).toList();
  }

  int get _selectedCount => _entries.where((e) => e.isSelected).length;
  int get _duplicateCount => _entries.where((e) => e.isDuplicate).length;

  void _toggleSelectAll(bool select) {
    setState(() {
      final currentList = _filteredEntries;
      for (final entry in currentList) {
        entry.isSelected = select;
      }
    });
  }

  Future<void> _handleImport() async {
    final selectedCount = _selectedCount;
    if (selectedCount == 0) return;

    setState(() => _isImporting = true);
    try {
      final count = await DeviceCalendarService.importEvents(
        _entries,
        color: _selectedColor,
      );

      // カレンダー表示Providerを無効化してリフレッシュ
      ref.invalidate(eventsByMonthProvider);
      ref.invalidate(eventsByDateProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count 件の予定を取り込みました。'),
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

    return BaseModal(
      title: '外部カレンダーから取り込み',
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return Column(
      children: [
        // 1. カレンダー選択 ＆ 期間設定エリア
        _buildFilterHeader(theme),

        const Divider(height: 1),

        // 2. 検索バー ＆ 一括選択バー ＆ カラーバー
        _buildSearchAndControlBar(theme),

        const Divider(height: 1),

        // 3. 予定リスト / ローディング / エラー / 空表示
        Expanded(
          child: _buildContent(theme),
        ),

        // 4. 下部固定インポートボタン
        _buildBottomBar(theme),
      ],
    );
  }

  Widget _buildFilterHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カレンダー選択ドロップダウン
          Row(
            children: [
              Icon(Icons.calendar_month, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              const Text('カレンダー:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCalendarId,
                    hint: const Text('カレンダーを選択', overflow: TextOverflow.ellipsis),
                    selectedItemBuilder: (context) {
                      return [
                        ..._calendars.map((c) {
                          final account = c.accountName != null && c.accountName!.isNotEmpty
                              ? ' (${c.accountName})'
                              : '';
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${c.name ?? "カレンダー"}$account',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_open_outlined, size: 16, color: Colors.teal),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'ファイル（.ics）',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                    items: [
                      ..._calendars.map((c) {
                        final account = c.accountName != null && c.accountName!.isNotEmpty
                            ? ' (${c.accountName})'
                            : '';
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(
                            '${c.name ?? "カレンダー"}$account',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: 'ics_file',
                        child: Row(
                          children: [
                            Icon(Icons.file_open_outlined, size: 16, color: Colors.teal),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'ファイル（.ics）から読み込み...',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      if (val == 'ics_file') {
                        _pickIcsFile();
                      } else {
                        setState(() {
                          _selectedCalendarId = val;
                        });
                        _fetchEvents();
                      }
                    },
                  ),
                ),
              ),
              if (_selectedCalendarId == 'ics_file')
                IconButton(
                  icon: const Icon(Icons.folder_open, size: 20),
                  tooltip: '別のファイルを選択',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: _pickIcsFile,
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: '再読み込み',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: _fetchEvents,
                ),
            ],
          ),

          if (_selectedCalendarId != 'ics_file') ...[
            const SizedBox(height: 6),
            // 期間指定セレクター
            Row(
              children: [
                Icon(Icons.date_range, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                const Text('取得期間:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_DateRangeOption>(
                      isExpanded: true,
                      value: _dateRangeOption,
                      items: _DateRangeOption.values.map((opt) {
                        return DropdownMenuItem<_DateRangeOption>(
                          value: opt,
                          child: Text(opt.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        if (val == _DateRangeOption.custom) {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          );
                          if (range != null) {
                            setState(() {
                              _dateRangeOption = _DateRangeOption.custom;
                              _startDate = range.start;
                              _endDate = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
                            });
                            _fetchEvents();
                          }
                        } else {
                          setState(() {
                            _applyDateRangeOption(val);
                          });
                          _fetchEvents();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                '${DateFormat('yyyy/MM/dd').format(_startDate)} 〜 ${DateFormat('yyyy/MM/dd').format(_endDate)}',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndControlBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // 検索ボックス
          TextField(
            decoration: InputDecoration(
              hintText: '予定名・メモで絞り込み...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 8),

          // 一括選択 ＆ 件数カウント
          Row(
            children: [
              Text(
                '${_filteredEntries.length}件中 $_selectedCount件選択'
                '${_duplicateCount > 0 ? "（重複$_duplicateCount件）" : ""}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _filteredEntries.isEmpty ? null : () => _toggleSelectAll(true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('全選択', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _filteredEntries.isEmpty ? null : () => _toggleSelectAll(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('全解除', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          // 取り込み時の予定カラー指定
          Row(
            children: [
              const Text('取り込みカラー: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showColorPickerDialog,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _selectedColor.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedColor.label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('予定の表示カラー', style: TextStyle(fontSize: 16)),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: EventColor.values.map((c) {
              final isSelected = c == _selectedColor;
              return InkWell(
                onTap: () {
                  setState(() => _selectedColor = c);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black87 : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('予定を読み込み中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initializeCalendars,
                icon: const Icon(Icons.refresh),
                label: const Text('権限を再確認・再試行'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickIcsFile,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('.icsファイルから直接読み込む'),
              ),
            ],
          ),
        ),
      );
    }

    final entries = _filteredEntries;
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? '条件に一致する予定がありません。' : '指定期間に予定が見つかりませんでした。',
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryTile(theme, entry);
      },
    );
  }

  Widget _buildEntryTile(ThemeData theme, DeviceCalendarEntry entry) {
    final dateFormat = DateFormat('M/d(E)', 'ja');
    final timeFormat = DateFormat('HH:mm');

    String dateText;
    if (entry.isAllDay) {
      dateText = '${dateFormat.format(entry.startDate)} 終日';
    } else {
      final isSameDay = entry.startDate.year == entry.endDate.year &&
          entry.startDate.month == entry.endDate.month &&
          entry.startDate.day == entry.endDate.day;
      if (isSameDay) {
        dateText = '${dateFormat.format(entry.startDate)} ${timeFormat.format(entry.startDate)} 〜 ${timeFormat.format(entry.endDate)}';
      } else {
        dateText = '${dateFormat.format(entry.startDate)} 〜 ${dateFormat.format(entry.endDate)}';
      }
    }

    return CheckboxListTile(
      value: entry.isSelected,
      onChanged: (val) {
        setState(() {
          entry.isSelected = val ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: entry.isDuplicate ? theme.hintColor : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (entry.isDuplicate)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '登録済み',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            dateText,
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
          if (entry.description != null && entry.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              entry.description!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: theme.hintColor.withAlpha(180)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final selectedCount = _selectedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: selectedCount > 0 && !_isImporting ? _handleImport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isImporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    selectedCount > 0 ? '$selectedCount 件の予定を取り込む' : '予定を選択してください',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
      ),
    );
  }
}

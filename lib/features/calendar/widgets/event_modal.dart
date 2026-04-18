import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';
import 'package:birthday_calendar/shared/widgets/multi_select_dialog.dart';
import 'package:birthday_calendar/shared/constants/japanese_holiday.dart';

/// スケジュール（イベント）の追加・編集を行うフルスクリーンモーダル。
class EventModal extends ConsumerStatefulWidget {
  /// 編集対象のイベント。nullの場合は新規作成モード。
  final EventModel? existingEvent;

  /// 新規作成時にあらかじめ設定しておく日付（タップされた日付など）。
  final DateTime? initialDate;

  const EventModal({
    super.key,
    this.existingEvent,
    this.initialDate,
  });

  @override
  ConsumerState<EventModal> createState() => _EventModalState();
}

class _EventModalState extends ConsumerState<EventModal> {
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  final _colorScrollController = ScrollController();

  bool _isAllDay = false;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSelectingStart = true; // 現在開始・終了のどちらを操作しているか
  EventColor _selectedColor = EventColor.peacock;
  RecurrenceType _recurrence = RecurrenceType.none;
  bool _isEndDateManuallyChanged = false;
  List<NotificationType> _notifications = [NotificationType.none];

  @override
  void initState() {
    super.initState();
    _initForm();

    // 画面表示後、選択中のカラーまでスクロール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_colorScrollController.hasClients) {
        // 画面に入りきっていない（スクロール可能）な場合のみ、選択中のカラーまでスクロール
        if (_colorScrollController.position.maxScrollExtent > 0) {
          final index = EventColor.values.indexOf(_selectedColor);
          if (index >= 0) {
            // 各カラーアイテムの幅(40) + マージン(12) = 52
            // 少し左側に余裕を持たせるか、中央付近に来るように調整（ここでは単純に位置へジャンプ）
            _colorScrollController.jumpTo(index * 52.0);
          }
        }
      }
    });
  }

  void _initForm() {
    final event = widget.existingEvent;
    if (event != null) {
      _titleController.text = event.title;
      _commentController.text = event.comment;
      _isAllDay = event.isAllDay;
      _startDate = event.startDate;
      _endDate = event.endDate;
      _selectedColor = event.colorIndex;
      _recurrence = event.recurrence;
      _notifications = List.from(event.notifications);
      _isEndDateManuallyChanged = true; // 編集時は同期しない
    } else {
      // 新規作成時の初期値
      final now = DateTime.now();
      _startDate = widget.initialDate ?? DateTime(now.year, now.month, now.day, now.hour, 0);
      _endDate = _startDate.add(const Duration(hours: 1));
    }

    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  void _showDateTimePickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DateTimePickerSheet(
          initialStart: _startDate,
          initialEnd: _endDate,
          isAllDay: _isAllDay,
          activeSideStart: _isSelectingStart,
          isEndDateManuallyChanged: _isEndDateManuallyChanged,
          onChanged: (newStart, newEnd, manuallyChanged) {
            setState(() {
              _startDate = newStart;
              _endDate = newEnd;
              if (manuallyChanged) {
                _isEndDateManuallyChanged = true;
              }
            });
          },
          onSideChanged: (isStart) {
            setState(() {
              _isSelectingStart = isStart;
            });
          },
        );
      },
    );
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final newEvent = EventModel(
      id: widget.existingEvent?.id,
      title: title,
      startDate: _startDate,
      endDate: _endDate,
      isAllDay: _isAllDay,
      colorIndex: _selectedColor,
      recurrence: _recurrence,
      notifications: _notifications,
      comment: _commentController.text.trim(),
    );

    if (widget.existingEvent == null) {
      // 新規追加
      await ref.read(eventsByDateProvider.notifier).addEvent(newEvent);
    } else {
      // 更新
      await ref.read(eventsByDateProvider.notifier).updateEvent(newEvent);
    }

    // 月カレンダーも更新指令
    ref.read(eventsByMonthProvider.notifier).refresh();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onDelete() async {
    if (widget.existingEvent?.id != null) {
      await ref.read(eventsByDateProvider.notifier).deleteEvent(widget.existingEvent!.id!);
      ref.read(eventsByMonthProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingEvent != null;
    final isSaveEnabled = _titleController.text.trim().isNotEmpty;

    // 通知名の連結
    final notificationLabel = _notifications.isEmpty || (_notifications.length == 1 && _notifications.first == NotificationType.none)
        ? 'なし'
        : _notifications.map((e) => e.label).join(', ');

    return BaseModal(
      title: isEditMode ? '予定を編集' : '予定を追加',
      isEditMode: isEditMode,
      isSaveActionEnabled: isSaveEnabled,
      onSave: _onSave,
      onDelete: _onDelete,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'タイトルを入力',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              autofocus: !isEditMode,
            ),
            const Divider(),

            // 終日トグル
            SwitchListTile(
              title: const Text('終日'),
              value: _isAllDay,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _isAllDay = val);
              },
            ),

            // 開始・終了日時選択エリア
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDateTimeCard(
                  title: '開始',
                  dateTime: _startDate,
                  isSelected: _isSelectingStart,
                  onTap: () {
                    setState(() => _isSelectingStart = true);
                    _showDateTimePickerSheet();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
                _buildDateTimeCard(
                  title: '終了',
                  dateTime: _endDate,
                  isSelected: !_isSelectingStart,
                  onTap: () {
                    setState(() => _isSelectingStart = false);
                    _showDateTimePickerSheet();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // カラー選択
            const SizedBox(height: 16),
            const Text('カラー', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              controller: _colorScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: EventColor.values.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black54, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const Divider(),

            // 繰り返し
            const SizedBox(height: 8),
            ListTile(
              title: const Text('繰り返し', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              subtitle: Text(_recurrence.label, style: const TextStyle(fontSize: 16, color: Colors.black)),
              trailing: const Icon(Icons.arrow_drop_down),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                final result = await showModalBottomSheet<RecurrenceType>(
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: RecurrenceType.values.map((type) {
                          return ListTile(
                            title: Text(type.label),
                            onTap: () => Navigator.pop(context, type),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
                if (result != null) {
                  setState(() => _recurrence = result);
                }
              },
            ),
            const Divider(),

            // 通知
            const SizedBox(height: 8),
            ListTile(
              title: const Text('通知', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              subtitle: Text(notificationLabel, style: const TextStyle(fontSize: 16, color: Colors.black)),
              trailing: const Icon(Icons.arrow_drop_down),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                final result = await showDialog<List<NotificationType>>(
                  context: context,
                  builder: (context) {
                    return MultiSelectDialog<NotificationType>(
                      items: NotificationType.values,
                      initialSelectedItems: _notifications,
                      title: '通知設定',
                      labelBuilder: (item) => item.label,
                      noneItem: NotificationType.none,
                    );
                  },
                );
                if (result != null) {
                  setState(() => _notifications = result);
                }
              },
            ),
            const Divider(),

            // メモ
            const Text('メモ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: '詳細を入力...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 5,
                minLines: 3,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required String title,
    required DateTime dateTime,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('M月d日');
    final weekdayFormat = DateFormat('E', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              )),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    dateFormat.format(dateTime),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${weekdayFormat.format(dateTime)})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (!_isAllDay) ...[
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(dateTime),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// カスタム日時ピッカーボトムシート
class _DateTimePickerSheet extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final bool isAllDay;
  final bool activeSideStart;
  final bool isEndDateManuallyChanged;
  final Function(DateTime start, DateTime end, bool manuallyChanged) onChanged;
  final Function(bool isStart) onSideChanged;

  const _DateTimePickerSheet({
    required this.initialStart,
    required this.initialEnd,
    required this.isAllDay,
    required this.activeSideStart,
    required this.isEndDateManuallyChanged,
    required this.onChanged,
    required this.onSideChanged,
  });

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _currentStart;
  late DateTime _currentEnd;
  late bool _editingStart;
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _currentStart = widget.initialStart;
    _currentEnd = widget.initialEnd;
    _editingStart = widget.activeSideStart;
    _viewMonth = DateTime(_editingStart ? _currentStart.year : _currentEnd.year, _editingStart ? _currentStart.month : _currentEnd.month, 1);
  }

  void _onDateSelected(DateTime date) {
    bool manuallyChanged = false;
    setState(() {
      if (_editingStart) {
        _currentStart = DateTime(
          date.year,
          date.month,
          date.day,
          _currentStart.hour,
          _currentStart.minute,
        );
        // 終日設定かつ終了日が未変更の場合、開始日に合わせて終了日も同期させる
        if (widget.isAllDay && !widget.isEndDateManuallyChanged) {
          _currentEnd = DateTime(
            date.year,
            date.month,
            date.day,
            _currentEnd.hour,
            _currentEnd.minute,
          );
        }
        
        if (_currentStart.isAfter(_currentEnd)) {
          _currentEnd = _currentStart.add(const Duration(hours: 1));
        }
      } else {
        _currentEnd = DateTime(
          date.year,
          date.month,
          date.day,
          _currentEnd.hour,
          _currentEnd.minute,
        );
        manuallyChanged = true; // 終了日が操作された
        if (_currentEnd.isBefore(_currentStart)) {
          _currentStart = _currentEnd.subtract(const Duration(hours: 1));
        }
      }
    });
    widget.onChanged(_currentStart, _currentEnd, manuallyChanged);
  }

  Future<void> _onTimeTap() async {
    final initialTime = _editingStart 
        ? TimeOfDay(hour: _currentStart.hour, minute: _currentStart.minute)
        : TimeOfDay(hour: _currentEnd.hour, minute: _currentEnd.minute);
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final wasEditingStart = _editingStart;
      setState(() {
        if (_editingStart) {
          _currentStart = DateTime(
            _currentStart.year,
            _currentStart.month,
            _currentStart.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (_currentStart.isAfter(_currentEnd)) {
            _currentEnd = _currentStart.add(const Duration(hours: 1));
          }
        } else {
          _currentEnd = DateTime(
            _currentEnd.year,
            _currentEnd.month,
            _currentEnd.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (_currentEnd.isBefore(_currentStart)) {
            _currentStart = _currentEnd.subtract(const Duration(hours: 1));
          }
        }
      });
      widget.onChanged(_currentStart, _currentEnd, !wasEditingStart);

      // 開始時刻を選択完了し、かつ開始・終了が同日の場合、自動で終了時刻ピッカーを開く
      if (wasEditingStart && _isSameDay(_currentStart, _currentEnd)) {
        setState(() {
          _editingStart = false;
        });
        widget.onSideChanged(false);
        
        // 連続してダイアログを開くために少しだけ待機
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _onTimeTap();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // 切り替えスイッチ 兼 表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTabButton('開始', _currentStart, _editingStart, () {
                  setState(() {
                    _editingStart = true;
                    _viewMonth = DateTime(_currentStart.year, _currentStart.month, 1);
                  });
                  widget.onSideChanged(true);
                }),
                const SizedBox(width: 12),
                _buildTabButton('終了', _currentEnd, !_editingStart, () {
                  setState(() {
                    _editingStart = false;
                    _viewMonth = DateTime(_currentEnd.year, _currentEnd.month, 1);
                  });
                  widget.onSideChanged(false);
                }),
              ],
            ),
          ),
          
          const Divider(height: 32),

          // カレンダーヘッダー（月切り替え）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1)),
                ),
                Text(
                  DateFormat('yyyy年 M月').format(_viewMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1)),
                ),
              ],
            ),
          ),

          // カスタムカレンダーグリッド
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _CustomCalendarPicker(
              viewMonth: _viewMonth,
              selectedDate: _editingStart ? _currentStart : _currentEnd,
              otherDate: _editingStart ? _currentEnd : _currentStart,
              onDateSelected: _onDateSelected,
            ),
          ),

          if (!widget.isAllDay) ...[
            const Divider(height: 24),
            // 時刻選択ボタン（時計ピッカー起動）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: _onTimeTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: themeColor),
                      const SizedBox(width: 8),
                      Text(
                        '時刻を選択: ${DateFormat('HH:mm').format(_editingStart ? _currentStart : _currentEnd)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('決定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, DateTime value, bool isActive, VoidCallback onTap) {
    final themeColor = Theme.of(context).primaryColor;
    final dateStr = DateFormat('M/d(E)', 'ja_JP').format(value);
    final timeStr = DateFormat('HH:mm').format(value);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? themeColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? themeColor : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive ? [BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white70 : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 2),
              Text('$dateStr ${widget.isAllDay ? "" : timeStr}', style: TextStyle(
                fontSize: 15,
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

/// カスタムカレンダーピッカーウィジェット
class _CustomCalendarPicker extends StatelessWidget {
  final DateTime viewMonth;
  final DateTime selectedDate;
  final DateTime otherDate;
  final Function(DateTime) onDateSelected;

  const _CustomCalendarPicker({
    required this.viewMonth,
    required this.selectedDate,
    required this.otherDate,
    required this.onDateSelected,
  });

  List<DateTime> _getDates() {
    final first = DateTime(viewMonth.year, viewMonth.month, 1);
    final offset = first.weekday % 7;
    final start = first.subtract(Duration(days: offset));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDates();
    final themeColor = Theme.of(context).primaryColor;
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];

    // 範囲ハイライト用の計算
    final startRange = selectedDate.isBefore(otherDate) ? selectedDate : otherDate;
    final endRange = selectedDate.isAfter(otherDate) ? selectedDate : otherDate;

    return Column(
      children: [
        // 曜日
        Row(
          children: weekdays.map((w) => Expanded(
            child: Center(child: Text(w, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // 日付グリッド
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            final date = dates[index];
            final isCurrentMonth = date.month == viewMonth.month;
            final isSelected = _isSameDay(date, selectedDate);
            final isOther = _isSameDay(date, otherDate);
            
            // 範囲内判定
            final isInRange = date.isAfter(startRange) && date.isBefore(endRange);
            final isRangeStart = _isSameDay(date, startRange);
            final isRangeEnd = _isSameDay(date, endRange);

            Color textColor = isCurrentMonth ? Colors.black87 : Colors.grey.shade300;
            if (isCurrentMonth) {
              if (JapaneseHoliday.isHoliday(date) || date.weekday == DateTime.sunday) {
                textColor = Colors.red.shade400;
              } else if (date.weekday == DateTime.saturday) {
                textColor = Colors.blue.shade400;
              }
            }
            if (isSelected) textColor = Colors.white;

            return GestureDetector(
              onTap: () => onDateSelected(date),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 範囲ハイライト
                  if (isInRange)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                      ),
                    ),
                  if (isRangeStart && !_isSameDay(startRange, endRange))
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 20,
                        height: 32,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1)),
                      ),
                    ),
                  if (isRangeEnd && !_isSameDay(startRange, endRange))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 32,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1)),
                      ),
                    ),

                  // 日付サークル
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isOther ? Border.all(color: themeColor, width: 2, style: BorderStyle.solid) : null,
                      boxShadow: isSelected ? [BoxShadow(color: themeColor.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))] : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (isSelected || isOther) ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  ),

                  // 他端を示すドット（枠線だけだと分かりにくい場合用）
                  if (isOther && !isSelected)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ユーティリティ
// -----------------------------------------------------------------------------

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

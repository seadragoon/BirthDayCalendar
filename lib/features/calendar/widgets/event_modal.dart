import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

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

  bool _isAllDay = false;
  late DateTime _startDate;
  late DateTime _endDate;
  EventColor _selectedColor = EventColor.peacock;
  RecurrenceType _recurrence = RecurrenceType.none;
  NotificationType _notification = NotificationType.none;

  @override
  void initState() {
    super.initState();
    _initForm();
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
      _notification = event.notification;
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
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _startDate.hour,
            _startDate.minute,
          );
          // 開始が終了を超えた場合、終了を合わせる
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(hours: 1));
          }
        } else {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _endDate.hour,
            _endDate.minute,
          );
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(hours: 1));
          }
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    if (_isAllDay) return;

    final initialTime = isStart
        ? TimeOfDay(hour: _startDate.hour, minute: _startDate.minute)
        : TimeOfDay(hour: _endDate.hour, minute: _endDate.minute);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(hours: 1));
          }
        } else {
          _endDate = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(hours: 1));
          }
        }
      });
    }
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
      notification: _notification,
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

    final dateFormat = DateFormat('yyyy年M月d日 (E)', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

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
              decoration: const InputDecoration(
                hintText: 'タイトルを入力',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

            // 開始・終了日時
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('開始', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _pickDate(true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dateFormat.format(_startDate), 
                            style: const TextStyle(fontSize: 16)
                          ),
                        ),
                      ),
                      if (!_isAllDay) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _pickTime(true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeFormat.format(_startDate), 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('終了', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _pickDate(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dateFormat.format(_endDate), 
                            style: const TextStyle(fontSize: 16)
                          ),
                        ),
                      ),
                      if (!_isAllDay) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _pickTime(false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeFormat.format(_endDate), 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),

            // カラー選択
            const SizedBox(height: 16),
            const Text('カラー', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SingleChildScrollView(
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
            const Divider(),

            // 繰り返し・通知
            InputDecorator(
              decoration: const InputDecoration(labelText: '繰り返し', border: InputBorder.none),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RecurrenceType>(
                  value: _recurrence,
                  isDense: true,
                  isExpanded: true,
                  items: RecurrenceType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                  onChanged: (val) => setState(() => _recurrence = val!),
                ),
              ),
            ),
            const Divider(),
            InputDecorator(
              decoration: const InputDecoration(labelText: '通知', border: InputBorder.none),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<NotificationType>(
                  value: _notification,
                  isDense: true,
                  isExpanded: true,
                  items: NotificationType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                  onChanged: (val) => setState(() => _notification = val!),
                ),
              ),
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
}

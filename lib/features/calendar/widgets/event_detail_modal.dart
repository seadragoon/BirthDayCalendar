import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_modal.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';
import 'package:birthday_calendar/shared/providers/repository_providers.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';

/// 予定の詳細を表示する読み取り専用モーダル
class EventDetailModal extends ConsumerStatefulWidget {
  final EventModel event;

  const EventDetailModal({super.key, required this.event});

  @override
  ConsumerState<EventDetailModal> createState() => _EventDetailModalState();
}

class _EventDetailModalState extends ConsumerState<EventDetailModal> {
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  Future<void> _refreshEvent() async {
    if (_currentEvent.id != null) {
      final updatedEvent = await ref.read(eventRepositoryProvider).getEventById(_currentEvent.id!);
      if (updatedEvent != null && mounted) {
        setState(() {
          _currentEvent = updatedEvent;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M月d日(E)', 'ja_JP');
    final titleDateStr = dateFormat.format(_currentEvent.startDate);

    return BaseModal(
      title: titleDateStr,
      isEditMode: true,
      onDelete: () async {
        if (_currentEvent.id != null) {
          await ref.read(eventsByDateProvider.notifier).deleteEvent(_currentEvent.id!);
          ref.read(eventsByMonthProvider.notifier).refresh();
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      customActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: '編集',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventModal(existingEvent: _currentEvent),
                fullscreenDialog: true,
              ),
            );
            // 編集から戻ったら最新情報を取得
            _refreshEvent();
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カラー & タイトル
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _currentEvent.colorIndex.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentEvent.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            
            // 時間
            _buildDetailRow(
              icon: Icons.access_time,
              title: '日時',
              content: _buildTimeText(),
            ),
            const Divider(),

            // 繰り返し
            if (_currentEvent.recurrence != RecurrenceType.none) ...[
              _buildDetailRow(
                icon: Icons.repeat,
                title: '繰り返し',
                content: Text(_currentEvent.recurrence.label, style: const TextStyle(fontSize: 16)),
              ),
              const Divider(),
            ],

            // 通知
            _buildDetailRow(
              icon: Icons.notifications_none,
              title: '通知',
              content: Text(
                _currentEvent.notifications.isEmpty || (_currentEvent.notifications.length == 1 && _currentEvent.notifications.first == NotificationType.none)
                    ? 'なし'
                    : _currentEvent.notifications.map((e) => e.label).join(', '),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Divider(),

            // メモ
            if (_currentEvent.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.notes,
                title: 'メモ',
                content: Text(
                  _currentEvent.comment,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeText() {
    final dateFormat = DateFormat('yyyy年 M月d日(E)', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

    // 日をまたぐイベントの判定
    final isSameDay = _currentEvent.startDate.year == _currentEvent.endDate.year &&
                      _currentEvent.startDate.month == _currentEvent.endDate.month &&
                      _currentEvent.startDate.day == _currentEvent.endDate.day;
    
    if (_currentEvent.isAllDay) {
      if (isSameDay) {
        return const Text('終日', style: TextStyle(fontSize: 16));
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${dateFormat.format(_currentEvent.startDate)} (終日)', style: const TextStyle(fontSize: 16)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text('   〜', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            Text('${dateFormat.format(_currentEvent.endDate)} (終日)', style: const TextStyle(fontSize: 16)),
          ],
        );
      }
    }

    if (isSameDay) {
      return Text(
        '${timeFormat.format(_currentEvent.startDate)} - ${timeFormat.format(_currentEvent.endDate)}',
        style: const TextStyle(fontSize: 16),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${dateFormat.format(_currentEvent.startDate)}  ${timeFormat.format(_currentEvent.startDate)}', style: const TextStyle(fontSize: 16)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text('   〜', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          Text('${dateFormat.format(_currentEvent.endDate)}  ${timeFormat.format(_currentEvent.endDate)}', style: const TextStyle(fontSize: 16)),
        ],
      );
    }
  }

  Widget _buildDetailRow({required IconData icon, required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

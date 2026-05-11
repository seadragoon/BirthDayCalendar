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
import 'package:birthday_calendar/features/calendar/models/edit_scope.dart';
import 'package:birthday_calendar/features/calendar/models/custom_recurrence.dart';

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
          if (updatedEvent.recurrence == RecurrenceType.none && updatedEvent.customRecurrence == null) {
            // 単発予定の場合は、日付変更なども含めてすべてそのまま反映する
            _currentEvent = updatedEvent;
          } else {
            // 繰り返し予定の場合、表示中の「特定の発生日」を維持しながら、時間・終日設定・その他のメタデータを反映する
            final newStart = DateTime(
              _currentEvent.startDate.year,
              _currentEvent.startDate.month,
              _currentEvent.startDate.day,
              updatedEvent.startDate.hour,
              updatedEvent.startDate.minute,
            );
            final duration = updatedEvent.endDate.difference(updatedEvent.startDate);
            final newEnd = newStart.add(duration);

            _currentEvent = _currentEvent.copyWith(
              title: updatedEvent.title,
              isAllDay: updatedEvent.isAllDay,
              startDate: newStart,
              endDate: newEnd,
              colorIndex: updatedEvent.colorIndex,
              recurrence: updatedEvent.recurrence,
              customRecurrence: updatedEvent.customRecurrence,
              notifications: updatedEvent.notifications,
              comment: updatedEvent.comment,
            );
          }
        });
      }
    }
  }

  Future<EditScope?> _showEditScopeDialog(String actionTitle) async {
    return showModalBottomSheet<EditScope>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(actionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                title: const Text('この予定のみ'),
                onTap: () => Navigator.pop(context, EditScope.thisEvent),
              ),
              ListTile(
                title: const Text('以降の予定'),
                onTap: () => Navigator.pop(context, EditScope.followingEvents),
              ),
              ListTile(
                title: const Text('全ての予定'),
                onTap: () => Navigator.pop(context, EditScope.all),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M月d日(E)', 'ja_JP');
    final titleDateStr = dateFormat.format(_currentEvent.startDate);

    return BaseModal(
      title: titleDateStr,
      isEditMode: true,
      customActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: '編集',
          onPressed: () async {
            EditScope scope = EditScope.all;
            EventModel? originalParent;
            
            if (_currentEvent.recurrence != RecurrenceType.none || _currentEvent.customRecurrence != null) {
              final repo = ref.read(eventRepositoryProvider);
              originalParent = await repo.getEventById(_currentEvent.id!);
              if (originalParent != null) {
                final selectedScope = await _showEditScopeDialog('予定の変更');
                if (selectedScope == null) return;
                scope = selectedScope;
              }
            }

            if (!context.mounted) return;
            
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventModal(
                  existingEvent: (scope == EditScope.all && originalParent != null) ? originalParent : _currentEvent,
                  originalParentEvent: originalParent,
                  editScope: scope,
                ),
                fullscreenDialog: true,
              ),
            );
            // 編集から戻ったら最新情報を取得
            // ※「以降の予定」などを選んだ場合はIDが変わるため、Detailを閉じるかリフレッシュするか微妙ですが、
            //   ここでは簡便のためポップします（リストビューに戻る）
            if (scope != EditScope.all && context.mounted) {
               Navigator.of(context).pop();
            } else {
               _refreshEvent();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: '削除',
          onPressed: () async {
            if (_currentEvent.id == null) return;

            EditScope scope = EditScope.all;
            EventModel? originalParent;
            
            if (_currentEvent.recurrence != RecurrenceType.none || _currentEvent.customRecurrence != null) {
              final repo = ref.read(eventRepositoryProvider);
              originalParent = await repo.getEventById(_currentEvent.id!);
              if (originalParent != null) {
                final selectedScope = await _showEditScopeDialog('予定の削除');
                if (selectedScope == null) return; // cancelled
                scope = selectedScope;
              }
            }

            if (!context.mounted) return;

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
                    child: const Text('削除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm != true) return;

            if (scope == EditScope.all) {
               await ref.read(eventsByDateProvider.notifier).deleteEvent(_currentEvent.id!);
            } else if (scope == EditScope.thisEvent && originalParent != null) {
               final occDate = DateTime(_currentEvent.startDate.year, _currentEvent.startDate.month, _currentEvent.startDate.day);
               
               if (!hasFollowingOccurrences(originalParent, occDate)) {
                 // 最後の予定なら「以降の予定」削除と同様に終了日を前倒しする（実質的に例外日ではなくシリーズの打ち切りとする）
                 final endBefore = _currentEvent.startDate.subtract(const Duration(days: 1));
                 EventModel newParent = originalParent;
                 if (newParent.recurrence != RecurrenceType.none && newParent.recurrence != RecurrenceType.custom) {
                    final converted = CustomRecurrence.fromStandard(newParent.recurrence, untilDate: endBefore);
                    newParent = newParent.copyWith(recurrence: RecurrenceType.custom, customRecurrence: converted);
                 } else if (newParent.customRecurrence != null) {
                    newParent = newParent.copyWith(customRecurrence: newParent.customRecurrence!.copyWith(endType: CustomEndType.date, endDate: endBefore));
                 }
                 await ref.read(eventsByDateProvider.notifier).updateEvent(newParent);
               } else {
                 // 通常の例外日追加
                 final newParent = originalParent.copyWith(
                   exceptionDates: [...originalParent.exceptionDates, occDate]
                 );
                 await ref.read(eventsByDateProvider.notifier).updateEvent(newParent);
               }
            } else if (scope == EditScope.followingEvents && originalParent != null) {
               final endBefore = _currentEvent.startDate.subtract(const Duration(days: 1));
               EventModel newParent = originalParent;
               if (newParent.recurrence != RecurrenceType.none && newParent.recurrence != RecurrenceType.custom) {
                  final converted = CustomRecurrence.fromStandard(newParent.recurrence, untilDate: endBefore);
                  newParent = newParent.copyWith(recurrence: RecurrenceType.custom, customRecurrence: converted);
               } else if (newParent.customRecurrence != null) {
                  newParent = newParent.copyWith(customRecurrence: newParent.customRecurrence!.copyWith(endType: CustomEndType.date, endDate: endBefore));
               }
               await ref.read(eventsByDateProvider.notifier).updateEvent(newParent);
            }

            ref.read(eventsByMonthProvider.notifier).refresh();
            if (!context.mounted) return;
            Navigator.of(context).pop();
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
            if (_currentEvent.recurrence != RecurrenceType.none || _currentEvent.customRecurrence != null) ...[
              _buildDetailRow(
                icon: Icons.repeat,
                title: '繰り返し',
                content: Text(
                  _currentEvent.recurrence == RecurrenceType.custom && _currentEvent.customRecurrence != null
                      ? _currentEvent.customRecurrence!.toReadableString()
                      : _currentEvent.recurrence.label,
                  style: const TextStyle(fontSize: 16),
                ),
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

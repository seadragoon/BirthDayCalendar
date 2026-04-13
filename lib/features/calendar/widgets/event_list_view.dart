import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';

/// 選択中の日付に該当するイベントをリスト表示するWidget。
///
/// 予定がない場合は「予定はありません」とプレースホルダを表示する。
class EventListView extends ConsumerWidget {
  const EventListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択中の日付に紐づくイベントを取得
    final eventsAsyncValue = ref.watch(eventsByDateProvider);

    return eventsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      data: (events) {
        if (events.isEmpty) {
          // イベントがない場合のプレースホルダ
          return const Center(
            child: Text(
              '予定はありません',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final timeFormat = DateFormat('HH:mm');

            // 終日イベントか、時刻指定イベントかで表示を分ける
            final timeText = event.isAllDay
                ? '終日'
                : '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}';

            return ListTile(
              leading: Container(
                width: 12,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: event.colorIndex.color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              title: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(timeText),
              onTap: () {
                // TODO(Phase 7): イベント表示モーダルを開く
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${event.title}」の詳細表示は Phase 7 で実装予定です')),
                );
              },
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_modal.dart';

/// 選択中の日付に該当するイベントをリスト表示するWidget。
class EventListView extends ConsumerWidget {
  const EventListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択中の日付に紐づくイベントを取得
    final eventsAsyncValue = ref.watch(eventsByDateProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final scrollController = ScrollController();

    // 判定用の基準日（時刻を切り捨てた DateTime）
    final selectedBase = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return eventsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Text(
              '予定はありません',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: ListView.separated(
            controller: scrollController,
            itemCount: events.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.black12,
            ),
            itemBuilder: (context, index) {
              final event = events[index];
              final timeFormat = DateFormat('HH:mm');

              // 開始日が選択日より前か
              final startBase = DateTime(
                event.startDate.year,
                event.startDate.month,
                event.startDate.day,
              );
              final isFromPrevDay = startBase.isBefore(selectedBase);

              // 終了日が選択日より後か
              final endBase = DateTime(
                event.endDate.year,
                event.endDate.month,
                event.endDate.day,
              );
              // 終了時刻が翌日0:00ちょうどで AllDay でない場合は、当日分として扱う（＝点線にしない）
              // 一方で 0:01 以降であれば翌日に跨いでいるため点線にする
              bool isToNextDay = endBase.isAfter(selectedBase);
              if (isToNextDay && !event.isAllDay) {
                // 翌日の0:00ちょうどに終わる場合は、その日（今日）で完結しているとみなす
                if (event.endDate.hour == 0 && event.endDate.minute == 0) {
                  isToNextDay = false;
                }
              }

              final timeText = event.isAllDay
                  ? '終日'
                  : '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}';

              return ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: _EventColorBar(
                  color: event.colorIndex.color,
                  isDottedTop: isFromPrevDay,
                  isDottedBottom: isToNextDay,
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  timeText,
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventModal(existingEvent: event),
                      fullscreenDialog: true,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// 予定リストの左側に表示されるカラーバーウィジェット
class _EventColorBar extends StatelessWidget {
  final Color color;
  final bool isDottedTop;
  final bool isDottedBottom;

  const _EventColorBar({
    required this.color,
    required this.isDottedTop,
    required this.isDottedBottom,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4, // 12から4にスリム化
      height: 40,
      child: CustomPaint(
        painter: _EventBarPainter(
          color: color,
          isDottedTop: isDottedTop,
          isDottedBottom: isDottedBottom,
        ),
      ),
    );
  }
}

class _EventBarPainter extends CustomPainter {
  final Color color;
  final bool isDottedTop;
  final bool isDottedBottom;

  _EventBarPainter({
    required this.color,
    required this.isDottedTop,
    required this.isDottedBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final Radius cornerRadius = Radius.circular(size.width / 2);
    final paint = Paint()..color = color;

    // --- 上半分の描画 ---
    if (isDottedTop) {
      _drawDashedSegment(canvas, 0, midY, size.width, color);
    } else {
      // 実線：上端のみ角丸
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, midY),
          topLeft: cornerRadius,
          topRight: cornerRadius,
        ),
        paint,
      );
    }

    // --- 下半分の描画 ---
    if (isDottedBottom) {
      _drawDashedSegment(canvas, midY, size.height, size.width, color);
    } else {
      // 実線：下端のみ角丸
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, midY, size.width, size.height - midY),
          bottomLeft: cornerRadius,
          bottomRight: cornerRadius,
        ),
        paint,
      );
    }
  }

  void _drawDashedSegment(
    Canvas canvas,
    double startY,
    double endY,
    double width,
    Color color,
  ) {
    final paint = Paint()..color = color;
    // 20px の範囲にドットが3つ以上入るよう調整 (3+4+3+4+3 = 17px)
    const double dashHeight = 3;
    const double dashSpace = 4;
    double currentY = startY;

    while (currentY < endY) {
      final h = (currentY + dashHeight > endY) ? endY - currentY : dashHeight;
      if (h > 0) {
        canvas.drawRect(Rect.fromLTWH(0, currentY, width, h), paint);
      }
      currentY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _EventBarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isDottedTop != isDottedTop ||
        oldDelegate.isDottedBottom != isDottedBottom;
  }
}

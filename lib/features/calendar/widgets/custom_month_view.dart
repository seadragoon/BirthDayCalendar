import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/constants/japanese_holiday.dart';

/// 横スワイプ可能で、5/6週可変高さ、祝日・色分け等に対応したカスタムカレンダー。
class CustomMonthView extends ConsumerStatefulWidget {
  const CustomMonthView({super.key});

  @override
  ConsumerState<CustomMonthView> createState() => _CustomMonthViewState();
}

class _CustomMonthViewState extends ConsumerState<CustomMonthView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 初期表示月を中心に設定（前後1000ヶ月をスワイプ可能範囲とする）
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 基準月（ページ1000）から指定ページまでの月オフセットを計算して返す
  DateTime _getMonthFromIndex(DateTime initialMonth, int index) {
    final monthOffset = index - 1000;
    return DateTime(initialMonth.year, initialMonth.month + monthOffset, 1);
  }

  @override
  Widget build(BuildContext context) {
    // 最初に設定されたcurrentMonthを基準にする（ビルド中に変わらないように）
    final initialMonth = ref.read(currentMonthProvider);

    return Column(
      children: [
        _buildWeekHeader(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              final newMonth = _getMonthFromIndex(initialMonth, index);
              // 月を切り替えたら currentMonthProvider を更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(currentMonthProvider.notifier).state = newMonth;
              });
            },
            itemBuilder: (context, index) {
              final month = _getMonthFromIndex(initialMonth, index);
              return _MonthGrid(month: month);
            },
          ),
        ),
      ],
    );
  }

  /// 曜日行を描画（日曜日から土曜日）
  Widget _buildWeekHeader() {
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        children: List.generate(7, (index) {
          // 日曜は赤、土曜は青、その他は黒
          Color color = Colors.black;
          if (index == 0) color = Colors.red;
          if (index == 6) color = Colors.blue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                weekdays[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  final DateTime month;

  const _MonthGrid({required this.month});

  List<DateTime> _getVisibleDates() {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // DateTime.weekday: Mon=1, Tue=2, ... Sun=7
    // 日曜日開始にするためのオフセット計算 (Sun=0, Mon=1, ... Sat=6)
    final offset = firstDay.weekday % 7;
    final startDate = firstDay.subtract(Duration(days: offset));

    final totalDays = lastDay.day + offset;
    final weeks = (totalDays / 7).ceil();

    final dates = <DateTime>[];
    DateTime current = startDate;
    for (int i = 0; i < weeks * 7; i++) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = _getVisibleDates();
    final weeks = dates.length ~/ 7;
    
    final eventsAsync = ref.watch(eventsByMonthProvider);
    final events = eventsAsync.valueOrNull ?? [];

    return Column(
      children: List.generate(weeks, (weekIndex) {
        return Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final date = dates[weekIndex * 7 + dayIndex];
              return Expanded(
                child: _DayCell(
                  date: date,
                  currentMonth: month,
                  events: events,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _DayCell extends ConsumerWidget {
  final DateTime date;
  final DateTime currentMonth;
  final List<EventModel> events;

  const _DayCell({
    required this.date,
    required this.currentMonth,
    required this.events,
  });

  /// この日に該当するイベントをフィルタリング
  List<EventModel> _getEventsForDay() {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return events.where((e) {
      return e.startDate.isBefore(dayEnd) && e.endDate.isAfter(dayStart);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isSelected = _isSameDay(date, selectedDate);
    final isCurrentMonth = date.month == currentMonth.month;

    // 日付文字色
    Color dateColor = Colors.black;
    if (!isCurrentMonth) {
      dateColor = Colors.grey.shade400; // 本月以外は薄く
    } else if (JapaneseHoliday.isHoliday(date)) {
      dateColor = Colors.red;
    } else if (date.weekday == DateTime.sunday) {
      dateColor = Colors.red;
    } else if (date.weekday == DateTime.saturday) {
      dateColor = Colors.blue;
    }

    final dayEvents = _getEventsForDay();

    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).state = date;
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Stack(
          children: [
            // 選択時の枠線
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1A237E), width: 2),
                ),
              ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 日付テキスト (左寄せ)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 4.0, bottom: 2.0),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: dateColor,
                    ),
                  ),
                ),
                // イベントバーエリア
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), // 親スクロール等との兼ね合いを避ける
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: dayEvents.map((e) => _buildEventBar(e)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBar(EventModel event) {
    // 終日イベント、または複数日イベントの場合は帯として処理
    final isStart = _isSameDay(event.startDate, date);
    final isEnd = _isSameDay(event.endDate, date);
    
    // 時刻指定で同日内のイベントなら単なる単日イベント
    final isSingleDay = _isSameDay(event.startDate, event.endDate);

    // 連結表現のための余白とRadius
    final leftMargin = (isStart || isSingleDay) ? 4.0 : 0.0;
    final rightMargin = (isEnd || isSingleDay) ? 4.0 : 0.0;
    
    final leftRadius = (isStart || isSingleDay) ? const Radius.circular(4) : Radius.zero;
    final rightRadius = (isEnd || isSingleDay) ? const Radius.circular(4) : Radius.zero;

    // テキストは開始日、単日、または週の初め（日曜日）に表示
    final showText = isStart || isSingleDay || date.weekday == DateTime.sunday;

    return Container(
      height: 16, // バーの高さ固定
      margin: EdgeInsets.only(
        left: leftMargin,
        right: rightMargin,
        bottom: 2.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: event.colorIndex.color,
        borderRadius: BorderRadius.horizontal(
          left: leftRadius,
          right: rightRadius,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: showText
          ? Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            )
          : const SizedBox.shrink(),
    );
  }
}

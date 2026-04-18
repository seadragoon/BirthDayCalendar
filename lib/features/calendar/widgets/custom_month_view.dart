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
  late DateTime _initialMonth;

  @override
  void initState() {
    super.initState();
    // 初期表示月を中心に設定（前後1000ヶ月をスワイプ可能範囲とする）
    _initialMonth = ref.read(currentMonthProvider);
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

  /// 指定した月からページインデックスを計算して返す
  int _getIndexFromMonth(DateTime initialMonth, DateTime targetMonth) {
    final yearDiff = targetMonth.year - initialMonth.year;
    final monthDiff = targetMonth.month - initialMonth.month;
    final totalMonths = yearDiff * 12 + monthDiff;
    return 1000 + totalMonths;
  }

  @override
  Widget build(BuildContext context) {
    // 外部（今日ボタン等）からの月変更を監視してカレンダーをスクロールさせる
    ref.listen<DateTime>(currentMonthProvider, (previous, next) {
      final targetPage = _getIndexFromMonth(_initialMonth, next);
      if (_pageController.hasClients) {
        final currentPage = _pageController.page?.round();
        if (currentPage != targetPage) {
          _pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        final newMonth = _getMonthFromIndex(_initialMonth, index);
        // 現在の Provider の値と異なる場合のみ更新（無限ループ防止）
        if (ref.read(currentMonthProvider) != newMonth) {
          ref.read(currentMonthProvider.notifier).state = newMonth;
        }
      },
      itemBuilder: (context, index) {
        final month = _getMonthFromIndex(_initialMonth, index);
        return _MonthGrid(month: month);
      },
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
      children: [
        _buildWeekHeader(),
        ...List.generate(weeks, (weekIndex) {
          final weekDates = dates.sublist(weekIndex * 7, (weekIndex + 1) * 7);
          final weeklyLanes = _calculateWeeklyLanes(weekDates, events);

          return Expanded(
            child: Row(
              children: List.generate(7, (dayIndex) {
                final date = weekDates[dayIndex];
                return Expanded(
                  child: _DayCell(
                    date: date,
                    dayIndex: dayIndex,
                    currentMonth: month,
                    lanes: weeklyLanes[date] ?? [],
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  /// 指定された期間（1週間）に対して、イベントをレーン（垂直段数）に割り当てる
  Map<DateTime, List<EventModel?>> _calculateWeeklyLanes(
      List<DateTime> weekDates, List<EventModel> allEvents) {
    final weekStart = weekDates.first;
    final weekEnd =
        weekDates.last.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    // その週に掛かっているイベントを抽出
    final weekEvents = allEvents.where((e) {
      return e.startDate.isBefore(weekEnd) && e.endDate.isAfter(weekStart);
    }).toList();

    // ソート: 開始日が早い順 > 期間が長い順
    weekEvents.sort((a, b) {
      final startCompare = a.startDate.compareTo(b.startDate);
      if (startCompare != 0) return startCompare;
      final durationA = a.endDate.difference(a.startDate);
      final durationB = b.endDate.difference(b.startDate);
      return durationB.compareTo(durationA);
    });

    // レーン割り当て: lanes[laneIndex][dayIndex]
    final lanes = <List<EventModel?>>[];

    for (final event in weekEvents) {
      int? assignedLane;
      for (int i = 0; i < lanes.length; i++) {
        bool canPlace = true;
        for (int d = 0; d < 7; d++) {
          final date = weekDates[d];
          final dayEnd =
              date.add(const Duration(hours: 23, minutes: 59, seconds: 59));
          if (event.startDate.isBefore(dayEnd) && event.endDate.isAfter(date)) {
            if (lanes[i][d] != null) {
              canPlace = false;
              break;
            }
          }
        }
        if (canPlace) {
          assignedLane = i;
          break;
        }
      }

      if (assignedLane == null) {
        assignedLane = lanes.length;
        lanes.add(List<EventModel?>.filled(7, null));
      }

      for (int d = 0; d < 7; d++) {
        final date = weekDates[d];
        final dayEnd =
            date.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        if (event.startDate.isBefore(dayEnd) && event.endDate.isAfter(date)) {
          lanes[assignedLane][d] = event;
        }
      }
    }

    // 日付ごとのリストに変換
    final result = <DateTime, List<EventModel?>>{};
    for (int d = 0; d < 7; d++) {
      final date = weekDates[d];
      final dayLanes = <EventModel?>[];
      for (int i = 0; i < lanes.length; i++) {
        dayLanes.add(lanes[i][d]);
      }
      result[date] = dayLanes;
    }

    return result;
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
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                weekdays[index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12, // 日付と同じサイズ
                  color: Colors.black, // 土日も黒色
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayCell extends ConsumerWidget {
  final DateTime date;
  final int dayIndex;
  final DateTime currentMonth;
  final List<EventModel?> lanes;

  const _DayCell({
    required this.date,
    required this.dayIndex,
    required this.currentMonth,
    required this.lanes,
  });

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


    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).state = date;
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            // グリッド線（背景レイヤー）
            // Border.all ではなく個別の Border を使うことで、
            // 予定バーが境界線の上を隙間なく通れるようにする
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    right: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    // 左端の列のみ左側の線を描画
                    left: dayIndex == 0
                        ? BorderSide(color: Colors.grey.shade200, width: 0.5)
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
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
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: lanes.map((e) => _buildEventBar(e)).toList(),
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

  Widget _buildEventBar(EventModel? event) {
    if (event == null) {
      // 空きレーンのためのスペーサー
      return const SizedBox(height: 18.0); // バー(16) + マージン(2)
    }

    // 終日イベント、または複数日イベントの場合は帯として処理
    final isStart = _isSameDay(event.startDate, date);
    final isEnd = _isSameDay(event.endDate, date);

    // 時刻指定で同日内のイベントなら単なる単日イベント
    final isSingleDay = _isSameDay(event.startDate, event.endDate);

    // 連結表現のための余白とRadius
    final leftMargin = (isStart || isSingleDay) ? 4.0 : 0.0;
    final rightMargin = (isEnd || isSingleDay) ? 4.0 : 0.0;

    final leftRadius =
        (isStart || isSingleDay) ? const Radius.circular(4) : Radius.zero;
    final rightRadius =
        (isEnd || isSingleDay) ? const Radius.circular(4) : Radius.zero;

    // テキストは開始日、単日、または週の初め（日曜日）に表示
    final showText = isStart || isSingleDay || date.weekday == DateTime.sunday;

    return Container(
      height: 16, // バーの高さ固定
      margin: EdgeInsets.only(
        left: leftMargin,
        right: rightMargin,
        bottom: 2.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: event.colorIndex.color,
          borderRadius: BorderRadius.horizontal(
            left: leftRadius,
            right: rightRadius,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/calendar/widgets/custom_month_view.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_list_view.dart';
import 'package:birthday_calendar/features/calendar/widgets/today_bar.dart';

/// カレンダーとイベントリストを組み合わせた、スケジュール画面のメインビュー。
class ScheduleView extends ConsumerWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 1. カレンダー部分
        const Expanded(
          flex: 6,
          child: CustomMonthView(),
        ),

        // 2. Today Bar (例: "4月6日 (月)")
        const TodayBar(),

        // 3. 今日の予定リスト
        const Expanded(
          flex: 4,
          child: EventListView(),
        ),
      ],
    );
  }
}

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/calendar_controller_provider.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_list_view.dart';
import 'package:birthday_calendar/features/calendar/widgets/today_bar.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';

/// カレンダーとイベントリストを組み合わせた、スケジュール画面のメインビュー。
class ScheduleView extends ConsumerWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // カレンダー用のコントローラを取得 (DBデータと自動同期される)
    final controller = ref.watch(calendarControllerProvider);
    final currentMonth = ref.watch(currentMonthProvider);

    return Column(
      children: [
        // 1. カレンダー部分
        Expanded(
          flex: 6,
          child: MonthView<EventModel>(
            controller: controller,
            // CustomHeaderで年月を表示しているため、パブリージ提供のヘッダーは非表示にする
            headerBuilder: (date) => const SizedBox.shrink(),
            // 初期表示の日付
            initialMonth: currentMonth,
            // 月をスワイプしたときに Provider も更新する
            onPageChange: (date, pageIndex) {
              // Build中にStateを変更しないようにFuture.microtask等で遅延させる
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 ref.read(currentMonthProvider.notifier).state = date;
              });
            },
            // 日付セルをタップしたときに選択日付としてProviderを更新
            onCellTap: (events, date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
            // 選択日付のデザインをカレンダー側でも強調したい場合は cellBuilder や border を設定可能
            // 一旦シンプルに利用
          ),
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

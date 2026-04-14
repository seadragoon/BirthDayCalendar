import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/constants/japanese_holiday.dart';

/// カレンダーとイベントリストの間に表示する、選択中の日付バー。
///
/// 例: "4月6日 (月)", または祝日の場合は "4月29日（水） 昭和の日" のように表示する。
class TodayBar extends ConsumerWidget {
  const TodayBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在選択中の日付を取得
    final selectedDate = ref.watch(selectedDateProvider);

    final monthDayFormat = DateFormat('M月d日');
    final weekdayFormat = DateFormat('E', 'ja_JP');

    final isHoliday = JapaneseHoliday.isHoliday(selectedDate);
    final holidayName = JapaneseHoliday.getHolidayName(selectedDate);

    // 曜日の色判定
    Color weekdayColor = Theme.of(context).colorScheme.onSurfaceVariant;
    if (isHoliday || selectedDate.weekday == DateTime.sunday) {
      weekdayColor = Colors.red;
    } else if (selectedDate.weekday == DateTime.saturday) {
      weekdayColor = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // 日付と（
          Text(
            '${monthDayFormat.format(selectedDate)}(',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          // 曜日
          Text(
            weekdayFormat.format(selectedDate),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: weekdayColor,
            ),
          ),
          // ）
          Text(
            ')',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          // 祝日名
          if (isHoliday && holidayName != null) ...[
            const SizedBox(width: 8),
            Text(
              holidayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

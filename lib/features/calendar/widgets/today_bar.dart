import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/shared/providers/app_state_providers.dart';

/// カレンダーとイベントリストの間に表示する、選択中の日付バー。
///
/// 例: "4月6日 (月)" のように表示する。
class TodayBar extends ConsumerWidget {
  const TodayBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在選択中の日付を取得
    final selectedDate = ref.watch(selectedDateProvider);

    // 日付フォーマット。「MM月dd日 (E)」は「04月06日 (月)」のようになるため、
    // ここではカスタムでフォーマットする
    final monthDayFormat = DateFormat('M月d日');
    final weekdayFormat = DateFormat('E', 'ja_JP');

    final dateText =
        '${monthDayFormat.format(selectedDate)} (${weekdayFormat.format(selectedDate)})';

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
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

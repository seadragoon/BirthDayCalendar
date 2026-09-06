import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/constants/japanese_holiday.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/constants/rokuyo_util.dart';
import 'package:birthday_calendar/features/calendar/widgets/stamp_picker_sheet.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_modal.dart';

/// カレンダーとイベントリストの間に表示する、選択中の日付バー。
///
/// 例: "4月6日 (月)", または祝日の場合は "4月29日（水） 昭和の日" のように表示する。
/// 右側にスタンプをワンタップでカレンダーに貼れるクイック追加ボタンを配置。
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

    // 六曜設定の取得
    final appSettings = ref.watch(appSettingsProvider).valueOrNull;
    final showRokuyo = appSettings?.showRokuyo ?? false;
    final rokuyo = showRokuyo ? RokuyoUtil.getRokuyo(selectedDate) : '';

    // 曜日の色判定
    Color weekdayColor = Theme.of(context).colorScheme.onSurfaceVariant;
    if (isHoliday || selectedDate.weekday == DateTime.sunday) {
      weekdayColor = Colors.red;
    } else if (selectedDate.weekday == DateTime.saturday) {
      weekdayColor = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
          // 六曜
          if (showRokuyo && rokuyo.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              rokuyo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: RokuyoUtil.isTaian(selectedDate)
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: RokuyoUtil.getTextColor(context, selectedDate, isCurrentMonth: true),
              ),
            ),
          ],
          // 祝日名
          if (isHoliday && holidayName != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                holidayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),

          // クイックスタンプ追加ボタン
          InkWell(
            onTap: () async {
              final stamp = await StampPickerSheet.show(context);
              if (stamp != null && stamp.id != 'clear' && stamp.icon.isNotEmpty) {
                final newEvent = EventModel(
                  title: stamp.label,
                  icon: stamp.icon,
                  startDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0),
                  endDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59),
                  isAllDay: true,
                  colorIndex: EventColor.lavender,
                );
                final savedEvent = await ref.read(eventsByDateProvider.notifier).addEvent(newEvent);
                await StampPickerSheet.recordUsage(stamp.id);
                ref.read(eventsByMonthProvider.notifier).refresh();

                if (!context.mounted) return;

                // 編集するかどうかの確認ダイアログを表示
                final action = await showDialog<_StampAction>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) {
                    final theme = Theme.of(dialogContext);
                    final dateText = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(selectedDate);

                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Row(
                        children: [
                          Text(stamp.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '「${stamp.label}」を追加しました',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 追加された日付の表示バッジ
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      children: [
                                        TextSpan(text: dateText),
                                        if (isHoliday && holidayName != null)
                                          TextSpan(
                                            text: ' $holidayName',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '予定の詳細（時間・メモ・通知など）を編集しますか？',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(_StampAction.cancel),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(_StampAction.done),
                          child: const Text('このまま完了'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(_StampAction.edit),
                          child: const Text('編集する'),
                        ),
                      ],
                    );
                  },
                );

                if (action == _StampAction.cancel) {
                  // 追加を取り消し（予定削除 ＋ 履歴削除 ＋ 再描画）
                  if (savedEvent.id != null) {
                    await ref.read(eventsByDateProvider.notifier).deleteEvent(savedEvent.id!);
                    await StampPickerSheet.removeRecentStamp(stamp.id);
                    ref.read(eventsByMonthProvider.notifier).refresh();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${stamp.icon}「${stamp.label}」の追加をキャンセルしました'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else if (action == _StampAction.edit && context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EventModal(existingEvent: savedEvent),
                      fullscreenDialog: true,
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_reaction_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'スタンプ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// スタンプ追加確認ダイアログの選択アクション
enum _StampAction {
  /// 追加を取り消し（予定削除）
  cancel,

  /// このまま追加を完了
  done,

  /// 予定編集画面へ遷移
  edit,
}

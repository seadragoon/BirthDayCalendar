import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';

/// ホーム画面ウィジェットに渡す予定（スケジュール）表示エントリモデル。
class WidgetScheduleItem {
  final int? id;
  final String title;
  final String dateLabel;
  final String timeLabel;
  final String colorHex;
  final String? icon;
  final bool isBirthday;
  final bool isAllDay;

  const WidgetScheduleItem({
    this.id,
    required this.title,
    required this.dateLabel,
    required this.timeLabel,
    required this.colorHex,
    this.icon,
    this.isBirthday = false,
    this.isAllDay = false,
  });

  /// [EventModel] と基準日（表示対象日）からウィジェット用エントリを生成する
  factory WidgetScheduleItem.fromEvent(EventModel event, DateTime baseToday) {
    // 日付ラベル判定（今日、明日、または M/d(E)）
    final eventDay = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
    final today = DateTime(baseToday.year, baseToday.month, baseToday.day);
    final diffDays = eventDay.difference(today).inDays;

    final String dateLabel;
    if (diffDays == 0) {
      dateLabel = '今日';
    } else if (diffDays == 1) {
      dateLabel = '明日';
    } else {
      const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
      final weekdayStr = weekdays[event.startDate.weekday - 1];
      dateLabel = '${event.startDate.month}/${event.startDate.day}($weekdayStr)';
    }

    // 時間ラベル判定
    final String timeLabel;
    if (event.isAllDay || event.isBirthday) {
      timeLabel = '終日';
    } else {
      final startTimeStr = DateFormat('H:mm').format(event.startDate);
      final endTimeStr = DateFormat('H:mm').format(event.endDate);
      timeLabel = '$startTimeStr - $endTimeStr';
    }

    // カラーHEX（#RRGGBB形式）
    final hexCode = (event.colorIndex.color.toARGB32() & 0x00FFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    final colorHex = '#$hexCode';

    return WidgetScheduleItem(
      id: event.id,
      title: event.title,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      colorHex: colorHex,
      icon: event.icon,
      isBirthday: event.isBirthday,
      isAllDay: event.isAllDay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date_label': dateLabel,
      'time_label': timeLabel,
      'color_hex': colorHex,
      'icon': icon ?? '',
      'is_birthday': isBirthday,
      'is_all_day': isAllDay,
    };
  }

  String toJson() => jsonEncode(toMap());
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/widget/models/widget_schedule_item.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';

void main() {
  group('WidgetScheduleItem Tests', () {
    final baseToday = DateTime(2026, 9, 6, 10, 0);

    test('fromEvent correctly formats for today with time', () {
      final eventToday = EventModel(
        id: 1,
        title: 'チーム定例',
        startDate: DateTime(2026, 9, 6, 14, 0),
        endDate: DateTime(2026, 9, 6, 15, 30),
        colorIndex: EventColor.lavender,
        icon: '💼',
      );

      final item = WidgetScheduleItem.fromEvent(eventToday, baseToday);
      expect(item.id, 1);
      expect(item.title, 'チーム定例');
      expect(item.dateLabel, '今日');
      expect(item.timeLabel, '14:00 - 15:30');
      expect(item.icon, '💼');
      expect(item.isAllDay, false);
      expect(item.colorHex, '#7986CB');
    });

    test('fromEvent correctly formats for tomorrow all-day event', () {
      final eventTomorrow = EventModel(
        id: 2,
        title: '出張',
        startDate: DateTime(2026, 9, 7, 0, 0),
        endDate: DateTime(2026, 9, 7, 23, 59),
        isAllDay: true,
        colorIndex: EventColor.tomato,
      );

      final item = WidgetScheduleItem.fromEvent(eventTomorrow, baseToday);
      expect(item.title, '出張');
      expect(item.dateLabel, '明日');
      expect(item.timeLabel, '終日');
      expect(item.isAllDay, true);
      expect(item.colorHex, '#D63838');
    });

    test('fromEvent correctly formats for future day and birthday event', () {
      final eventFuture = EventModel(
        id: -100,
        title: '花子の誕生日',
        startDate: DateTime(2026, 9, 10, 0, 0),
        endDate: DateTime(2026, 9, 10, 23, 59),
        isBirthday: true,
        icon: '🎂',
        colorIndex: EventColor.basil,
      );

      final item = WidgetScheduleItem.fromEvent(eventFuture, baseToday);
      expect(item.title, '花子の誕生日');
      expect(item.dateLabel, contains('9/10'));
      expect(item.timeLabel, '終日');
      expect(item.isBirthday, true);
      expect(item.colorHex, '#11A659');
    });

    test('toMap and toJson serialization works properly', () {
      const item = WidgetScheduleItem(
        id: 5,
        title: '映画鑑賞',
        dateLabel: '今日',
        timeLabel: '18:00 - 20:00',
        colorHex: '#8E24AA',
        icon: '🎬',
      );

      final jsonStr = item.toJson();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['id'], 5);
      expect(decoded['title'], '映画鑑賞');
      expect(decoded['date_label'], '今日');
      expect(decoded['time_label'], '18:00 - 20:00');
      expect(decoded['color_hex'], '#8E24AA');
      expect(decoded['icon'], '🎬');
    });

    test('null icon is serialized as empty string to avoid JSONObject optString null string', () {
      const item = WidgetScheduleItem(
        id: 6,
        title: '散歩',
        dateLabel: '今日',
        timeLabel: '終日',
        colorHex: '#7986CB',
        icon: null,
      );

      final jsonStr = item.toJson();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['icon'], '');
    });
  });
}

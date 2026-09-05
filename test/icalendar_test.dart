import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_calendar/features/backup/services/icalendar_service.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';

void main() {
  group('ICalendarService Tests', () {
    test('generateIcsContent generates valid iCalendar format', () {
      final events = [
        EventModel(
          id: 1,
          title: '定例会議',
          startDate: DateTime(2026, 9, 10, 10, 0),
          endDate: DateTime(2026, 9, 10, 11, 0),
          recurrence: RecurrenceType.weekly,
          comment: 'プロジェクト進捗確認',
          icon: '💼',
        ),
      ];

      final birthdays = [
        BirthdayModel(
          id: 1,
          name: '田中 太郎',
          date: DateTime(1990, 5, 15),
          tags: ['友達'],
          comment: '高校の同級生',
        ),
      ];

      final ics = ICalendarService.generateIcsContent(events, birthdays);

      // 基本ヘッダー
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('END:VCALENDAR'));

      // 予定イベント
      expect(ics, contains('SUMMARY:💼 定例会議'));
      expect(ics, contains('DESCRIPTION:プロジェクト進捗確認'));
      expect(ics, contains('RRULE:FREQ=WEEKLY'));

      // 誕生日イベント
      expect(ics, contains('SUMMARY:🎂 田中 太郎の誕生日'));
      expect(ics, contains('RRULE:FREQ=YEARLY'));
      expect(ics, contains('VALUE=DATE:19900515'));
    });
  });
}

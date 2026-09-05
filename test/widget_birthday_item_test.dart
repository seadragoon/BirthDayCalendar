import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/widget/models/widget_birthday_item.dart';

void main() {
  group('WidgetBirthdayItem Tests', () {
    test('fromBirthday correctly formats for known birth year', () {
      final now = DateTime.now();
      // 今日の日付で誕生日を作成
      final bToday = BirthdayModel(
        id: 1,
        name: '山田 太郎',
        date: DateTime(1995, now.month, now.day),
      );

      final itemToday = WidgetBirthdayItem.fromBirthday(bToday);
      expect(itemToday.name, '山田 太郎');
      expect(itemToday.daysLabel, '今日！');
      expect(itemToday.daysUntil, 0);
      expect(itemToday.dateLabel, contains('${now.month}月${now.day}日'));

      final json = itemToday.toMap();
      expect(json['name'], '山田 太郎');
      expect(json['days_label'], '今日！');
      expect(json['days_until'], 0);
    });

    test('fromBirthday correctly formats for unknown birth year', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 3));

      final bUnknown = BirthdayModel(
        id: 2,
        name: '鈴木 花子',
        date: DateTime(targetDate.year, targetDate.month, targetDate.day),
        isYearUnknown: true,
      );

      final item = WidgetBirthdayItem.fromBirthday(bUnknown);
      expect(item.name, '鈴木 花子');
      expect(item.daysUntil, 3);
      expect(item.daysLabel, 'あと3日');
      expect(item.dateLabel, '${targetDate.month}月${targetDate.day}日');
      expect(item.dateLabelShort, '${targetDate.month}/${targetDate.day}');
    });

    test('toMap and toJson serialization works properly', () {
      const item = WidgetBirthdayItem(
        id: 10,
        name: '佐藤 一郎',
        dateLabel: '5月20日 (25歳)',
        dateLabelShort: '5/20',
        daysLabel: '明日！',
        daysUntil: 1,
      );

      final jsonStr = item.toJson();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['id'], 10);
      expect(decoded['name'], '佐藤 一郎');
      expect(decoded['days_label'], '明日！');
      expect(decoded['days_until'], 1);
    });
  });
}

import 'dart:convert';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';

/// ホーム画面ウィジェットに渡す誕生日表示エントリモデル。
class WidgetBirthdayItem {
  final int? id;
  final String name;
  final String dateLabel;
  final String dateLabelShort;
  final String daysLabel;
  final int daysUntil;

  const WidgetBirthdayItem({
    this.id,
    required this.name,
    required this.dateLabel,
    required this.dateLabelShort,
    required this.daysLabel,
    required this.daysUntil,
  });

  /// [BirthdayModel] からウィジェット用エントリを生成する
  factory WidgetBirthdayItem.fromBirthday(BirthdayModel birthday) {
    final days = birthday.daysUntilNextBirthday;
    final String daysText;
    if (days == 0) {
      daysText = '今日！';
    } else if (days == 1) {
      daysText = '明日！';
    } else {
      daysText = 'あと$days日';
    }

    final String dateText;
    if (birthday.isYearUnknown || birthday.ageThisYear == null) {
      dateText = '${birthday.date.month}月${birthday.date.day}日';
    } else {
      dateText = '${birthday.date.month}月${birthday.date.day}日 (${birthday.ageThisYear}歳)';
    }

    final String dateTextShort = '${birthday.date.month}/${birthday.date.day}';

    return WidgetBirthdayItem(
      id: birthday.id,
      name: birthday.name,
      dateLabel: dateText,
      dateLabelShort: dateTextShort,
      daysLabel: daysText,
      daysUntil: days,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date_label': dateLabel,
      'date_label_short': dateLabelShort,
      'days_label': daysLabel,
      'days_until': daysUntil,
    };
  }

  String toJson() => jsonEncode(toMap());
}

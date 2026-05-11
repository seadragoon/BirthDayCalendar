import 'dart:convert';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';

enum CustomRecurrenceUnit { days, weeks, months, years }
enum CustomMonthType { dayOfMonth, nthWeekday }
enum CustomEndType { none, date, count }

/// カスタム繰り返し設定を保持・管理するためのデータモデル。
class CustomRecurrence {
  final int interval;
  final CustomRecurrenceUnit unit;
  final List<int>? daysOfWeek; // 1-7 (Mon-Sun), only used when unit == weeks
  final CustomMonthType? monthType; // used when unit == months
  final bool isWeekday; // true if repeating on weekdays (Mon-Fri, excluding holidays)
  final CustomEndType endType;
  final DateTime? endDate; // used when endType == date
  final int? count; // used when endType == count

  const CustomRecurrence({
    required this.interval,
    required this.unit,
    this.daysOfWeek,
    this.monthType,
    this.isWeekday = false,
    this.endType = CustomEndType.none,
    this.endDate,
    this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'interval': interval,
      'unit': unit.index,
      'daysOfWeek': daysOfWeek,
      'monthType': monthType?.index,
      'isWeekday': isWeekday ? 1 : 0,
      'endType': endType.index,
      'endDate': endDate?.millisecondsSinceEpoch,
      'count': count,
    };
  }

  factory CustomRecurrence.fromMap(Map<String, dynamic> map) {
    return CustomRecurrence(
      interval: map['interval'] as int? ?? 1,
      unit: CustomRecurrenceUnit.values[(map['unit'] as int?) ?? 0],
      daysOfWeek: (map['daysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList(),
      monthType: map['monthType'] != null ? CustomMonthType.values[map['monthType'] as int] : null,
      isWeekday: map['isWeekday'] == 1,
      endType: CustomEndType.values[(map['endType'] as int?) ?? 0],
      endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int) : null,
      count: map['count'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomRecurrence.fromJson(String source) => CustomRecurrence.fromMap(json.decode(source) as Map<String, dynamic>);

  CustomRecurrence copyWith({
    int? interval,
    CustomRecurrenceUnit? unit,
    List<int>? daysOfWeek,
    CustomMonthType? monthType,
    bool? isWeekday,
    CustomEndType? endType,
    DateTime? endDate,
    int? count,
  }) {
    return CustomRecurrence(
      interval: interval ?? this.interval,
      unit: unit ?? this.unit,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      monthType: monthType ?? this.monthType,
      isWeekday: isWeekday ?? this.isWeekday,
      endType: endType ?? this.endType,
      endDate: endDate ?? this.endDate,
      count: count ?? this.count,
    );
  }

  /// 現在の設定に合わせて、シンプルな設定に置き換えられる場合は [RecurrenceType] を返す
  RecurrenceType toStandardType(DateTime startDate) {
    if (interval != 1) return RecurrenceType.custom;
    if (endType != CustomEndType.none) return RecurrenceType.custom;

    if (unit == CustomRecurrenceUnit.days) return RecurrenceType.daily;
    if (unit == CustomRecurrenceUnit.years) return RecurrenceType.yearly;
    
    if (unit == CustomRecurrenceUnit.weeks) {
      if (isWeekday) return RecurrenceType.weekday;
      if (daysOfWeek == null || daysOfWeek!.isEmpty) {
        return RecurrenceType.weekly;
      }
      if (daysOfWeek!.length == 1 && daysOfWeek!.first == startDate.weekday) {
        return RecurrenceType.weekly;
      }
      final sortedDays = List<int>.from(daysOfWeek!)..sort();
      if (sortedDays.length == 5 && 
          sortedDays[0] == 1 && sortedDays[1] == 2 && 
          sortedDays[2] == 3 && sortedDays[3] == 4 && sortedDays[4] == 5) {
        return RecurrenceType.weekday;
      }
    }

    if (unit == CustomRecurrenceUnit.months) {
      if (monthType == CustomMonthType.dayOfMonth || monthType == null) {
        return RecurrenceType.monthly;
      }
    }

    return RecurrenceType.custom;
  }

  /// 画面上部に表示するためのルール概要テキスト
  String toReadableString() {
    String str = '';
    switch (unit) {
      case CustomRecurrenceUnit.days:
        str = interval == 1 ? '毎日' : '$interval日ごと';
        break;
      case CustomRecurrenceUnit.weeks:
        str = interval == 1 ? '毎週' : '$interval週間ごと';
        if (isWeekday) {
          str += ' (平日 ※祝日除く)';
        } else if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
           final sortedDays = List<int>.from(daysOfWeek!)..sort((a,b) {
               // 日曜を先頭にするアプローチ（アプリ全体の方針に合わせる。ここでは一旦月〜日にする）
               return a.compareTo(b);
           });
          final weekdaysText = sortedDays.map((d) {
            switch (d) {
              case 1: return '月';
              case 2: return '火';
              case 3: return '水';
              case 4: return '木';
              case 5: return '金';
              case 6: return '土';
              case 7: return '日';
              default: return '';
            }
          }).join(', ');
          str += ' ($weekdaysText)';
        }
        break;
      case CustomRecurrenceUnit.months:
        str = interval == 1 ? '毎月' : '$intervalか月ごと';
        if (monthType == CustomMonthType.nthWeekday) {
          str += ' (曜日指定)';
        } else {
          str += ' (日付指定)';
        }
        break;
      case CustomRecurrenceUnit.years:
        str = interval == 1 ? '毎年' : '$interval年ごと';
        break;
    }

    switch (endType) {
      case CustomEndType.none:
        break;
      case CustomEndType.date:
        if (endDate != null) {
          str += '、${endDate!.year}年${endDate!.month}月${endDate!.day}日まで';
        }
        break;
      case CustomEndType.count:
        if (count != null) {
          str += '、$count回で終了';
        }
        break;
    }

    return str;
  }

  /// 既存の [RecurrenceType] と終了条件を元に、[CustomRecurrence] を作成して返す
  static CustomRecurrence fromStandard(RecurrenceType type, {DateTime? untilDate}) {
    final endType = untilDate != null ? CustomEndType.date : CustomEndType.none;

    switch (type) {
      case RecurrenceType.daily:
        return CustomRecurrence(interval: 1, unit: CustomRecurrenceUnit.days, endType: endType, endDate: untilDate);
      case RecurrenceType.weekly:
        return CustomRecurrence(interval: 1, unit: CustomRecurrenceUnit.weeks, endType: endType, endDate: untilDate);
      case RecurrenceType.monthly:
        return CustomRecurrence(interval: 1, unit: CustomRecurrenceUnit.months, monthType: CustomMonthType.dayOfMonth, endType: endType, endDate: untilDate);
      case RecurrenceType.yearly:
        return CustomRecurrence(interval: 1, unit: CustomRecurrenceUnit.years, endType: endType, endDate: untilDate);
      case RecurrenceType.weekday:
        return CustomRecurrence(interval: 1, unit: CustomRecurrenceUnit.weeks, isWeekday: true, endType: endType, endDate: untilDate);
      default:
        // none または custom
        return CustomRecurrence(interval: 1, unit: CustomRecurrenceUnit.days, endType: endType, endDate: untilDate);
    }
  }
}

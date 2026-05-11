import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/repositories/event_repository.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/features/settings/models/birthday_display_settings.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/providers/repository_providers.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';
import 'package:birthday_calendar/shared/constants/japanese_holiday.dart';
import 'package:birthday_calendar/features/calendar/models/custom_recurrence.dart';

/// 選択中の日付に紐づくイベント一覧を提供するProvider。
final eventsByDateProvider =
    AsyncNotifierProvider<EventsByDateNotifier, List<EventModel>>(
  EventsByDateNotifier.new,
);

/// 選択中の日付に紐づくイベントを管理するNotifier。
class EventsByDateNotifier extends AsyncNotifier<List<EventModel>> {
  late EventRepository _repository;

  @override
  Future<List<EventModel>> build() async {
    _repository = ref.watch(eventRepositoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    
    // DBからのイベント取得
    final events = await _repository.getEventsByDate(selectedDate);

    // 重複を避けるため、繰り返し予定を展開してからマージする
    final expandedEvents = _expandEvents(events, selectedDate, selectedDate);
    
    // 誕生日のマージ処理
    final settingsAsync = ref.watch(birthdayDisplaySettingsProvider);
    final birthdaysAsync = ref.watch(birthdayListProvider);
    
    final settings = settingsAsync.valueOrNull;
    final birthdays = birthdaysAsync.valueOrNull;
    
    if (settings != null && settings.isShowOnSchedule && birthdays != null) {
      final birthdayEvents = _generateBirthdayEvents(
        birthdays, 
        settings, 
        selectedDate, 
        selectedDate
      );
      final merged = [...expandedEvents, ...birthdayEvents];
      // 誕生日を優先、その後に開始時刻順でソート
      merged.sort((a, b) {
        if (a.isBirthday && !b.isBirthday) return -1;
        if (!a.isBirthday && b.isBirthday) return 1;
        return a.startDate.compareTo(b.startDate);
      });
      return merged;
    }
    
    return expandedEvents;
  }

  /// イベントを追加し、リストを再取得する。
  Future<void> addEvent(EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertEvent(event);
      return build(); // build() を再実行して誕生日込みで取得
    });
  }

  /// イベントを更新し、リストを再取得する。
  Future<void> updateEvent(EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateEvent(event);
      return build();
    });
  }

  /// イベントを削除し、リストを再取得する。
  Future<void> deleteEvent(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteEvent(id);
      return build();
    });
  }
}

/// 表示中の月に含まれるイベント一覧を提供するProvider。
final eventsByMonthProvider =
    AsyncNotifierProvider<EventsByMonthNotifier, List<EventModel>>(
  EventsByMonthNotifier.new,
);

/// 表示中の月に含まれるイベントを管理するNotifier。
class EventsByMonthNotifier extends AsyncNotifier<List<EventModel>> {
  late EventRepository _repository;

  @override
  Future<List<EventModel>> build() async {
    _repository = ref.watch(eventRepositoryProvider);
    final currentMonth = ref.watch(currentMonthProvider);

    // 月の初日から末日までの範囲を計算
    final start = DateTime(currentMonth.year, currentMonth.month, 1);
    final end = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    // カレンダーの6週間表示（前後月の数日が表示される）を考慮し、取得・展開範囲を前後7日間広げる
    final rangeStart = start.subtract(const Duration(days: 7));
    final rangeEnd = end.add(const Duration(days: 7));
    
    // DBからのイベント取得
    final events = await _repository.getEventsByDateRange(rangeStart, rangeEnd);

    // 繰り返し予定の展開
    final expandedEvents = _expandEvents(events, rangeStart, rangeEnd);

    // 誕生日のマージ処理
    final settingsAsync = ref.watch(birthdayDisplaySettingsProvider);
    final birthdaysAsync = ref.watch(birthdayListProvider);
    
    final settings = settingsAsync.valueOrNull;
    final birthdays = birthdaysAsync.valueOrNull;
    
    if (settings != null && settings.isShowOnSchedule && birthdays != null) {
      final birthdayEvents = _generateBirthdayEvents(birthdays, settings, rangeStart, rangeEnd);
      return [...expandedEvents, ...birthdayEvents];
    }

    return expandedEvents;
  }

  /// データを強制的に再取得する。
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return build();
    });
  }
}

/// 指定したイベントの、特定のoccurrenceDateよりも後に予定が存在するか判定する。
/// 有限繰り返しの「最後の予定」かどうかの判定に使用。
bool hasFollowingOccurrences(EventModel event, DateTime occDate) {
  if (event.recurrence == RecurrenceType.none) return false;
  if (event.recurrence != RecurrenceType.custom) return true; // 標準の繰り返しは無限
  if (event.customRecurrence?.endType == CustomEndType.none) return true; // 期限なしは無限
  
  // 有限の場合は100年先までを対象に展開して存在をチェックする（展開処理自体は終了条件で早期ブレイクする）
  final futureEvents = _expandEvents([event], occDate.add(const Duration(days: 1)), occDate.add(const Duration(days: 365 * 100)));
  return futureEvents.isNotEmpty;
}

/// 繰り返し予定を指定された期間に合わせて展開する。
List<EventModel> _expandEvents(List<EventModel> events, DateTime start, DateTime end) {
  final results = <EventModel>[];
  final rangeStart = DateTime(start.year, start.month, start.day);
  final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

  for (final event in events) {
    if (event.recurrence == RecurrenceType.none) {
      // 期間内に重なるか最終チェック（念のため）
      if (event.startDate.isBefore(rangeEnd) && event.endDate.isAfter(rangeStart)) {
        results.add(event);
      }
      continue;
    }

    // 例外日の判定用ヘルパー
    bool isExceptionDate(DateTime occurrenceStart) {
      final ymd = DateTime(occurrenceStart.year, occurrenceStart.month, occurrenceStart.day);
      return event.exceptionDates.any((d) => 
        d.year == ymd.year && d.month == ymd.month && d.day == ymd.day
      );
    }

    final duration = event.endDate.difference(event.startDate);
    
    // カスタム繰り返しの展開処理
    if (event.recurrence == RecurrenceType.custom && event.customRecurrence != null) {
      final custom = event.customRecurrence!;
      int count = 0;
      DateTime occStart = event.startDate;
      
      while (occStart.isBefore(rangeEnd.add(const Duration(seconds: 1)))) {
        // 先に祝日かどうか判定（平日指定の場合は祝日をスキップ）
        bool isHolidaySkip = false;
        if (custom.isWeekday && JapaneseHoliday.isHoliday(occStart)) {
            isHolidaySkip = true;
        }

        if (!isHolidaySkip) {
          // 終了条件チェック (Date)
          if (custom.endType == CustomEndType.date && custom.endDate != null) {
            final eDate = custom.endDate!;
            final eDateYMD = DateTime(eDate.year, eDate.month, eDate.day, 23, 59, 59);
            if (occStart.isAfter(eDateYMD)) break;
          }
          // 終了条件チェック (Count)
          if (custom.endType == CustomEndType.count && custom.count != null) {
            if (count >= custom.count!) break;
          }

          // occStartが生成されたら、追加する（期間内＆例外日でない）
          DateTime occEnd = occStart.add(duration);
          if (occStart.isBefore(rangeEnd) && occEnd.isAfter(rangeStart)) {
            if (!isExceptionDate(occStart)) {
              results.add(event.copyWith(startDate: occStart, endDate: occEnd));
            }
          }
          
          count++;
        }

        // 次の予定日を計算
        // weekで複数曜日指定がある場合はやや複雑。簡易なインターバル加算を定義
        if (custom.unit == CustomRecurrenceUnit.days) {
          occStart = occStart.add(Duration(days: custom.interval));
        } else if (custom.unit == CustomRecurrenceUnit.years) {
          occStart = DateTime(occStart.year + custom.interval, occStart.month, occStart.day, occStart.hour, occStart.minute);
        } else if (custom.unit == CustomRecurrenceUnit.months) {
          if (custom.monthType == CustomMonthType.dayOfMonth || custom.monthType == null) {
             occStart = DateTime(occStart.year, occStart.month + custom.interval, occStart.day, occStart.hour, occStart.minute);
          } else {
             // 第n曜日
             final weekNum = ((event.startDate.day - 1) ~/ 7) + 1;
             final targetWeekday = event.startDate.weekday;
             final targetMonth = DateTime(occStart.year, occStart.month + custom.interval, 1);
             int offset = targetWeekday - targetMonth.weekday;
             if (offset < 0) offset += 7;
             final targetDay = 1 + offset + (weekNum - 1) * 7;
             // 月末超え等は厳密には調整が必要だが、ここでは簡易化
             occStart = DateTime(targetMonth.year, targetMonth.month, targetDay, occStart.hour, occStart.minute);
          }
        } else if (custom.unit == CustomRecurrenceUnit.weeks) {
           if (custom.isWeekday) {
               // 平日（月～金）
               final sortedDays = [1, 2, 3, 4, 5];
               int currentWd = occStart.weekday;
               int nextWd = -1;
               for (int wd in sortedDays) {
                 if (wd > currentWd) { nextWd = wd; break; }
               }
               if (nextWd != -1) {
                  int diff = nextWd - currentWd;
                  occStart = occStart.add(Duration(days: diff));
               } else {
                  int diffToSunday = 7 - currentWd;
                  int diffToNextTarget = diffToSunday + sortedDays.first;
                  occStart = occStart.add(Duration(days: diffToNextTarget + (custom.interval - 1) * 7));
               }
           } else if (custom.daysOfWeek != null && custom.daysOfWeek!.isNotEmpty) {
               // 複数曜日の場合、今のoccStartの次の曜日を探す。
               final sortedDays = List<int>.from(custom.daysOfWeek!)..sort();
               int currentWd = occStart.weekday;
               int nextWd = -1;
               for (int wd in sortedDays) {
                 if (wd > currentWd) { nextWd = wd; break; }
               }
               if (nextWd != -1) {
                  // 同週の次の該当曜日
                  int diff = nextWd - currentWd;
                  occStart = occStart.add(Duration(days: diff));
               } else {
                  // 次の該当曜日へのジャンプ ＋ インターバル加算
                  int diffToSunday = 7 - currentWd;
                  int diffToNextTarget = diffToSunday + sortedDays.first;
                  occStart = occStart.add(Duration(days: diffToNextTarget + (custom.interval - 1) * 7));
               }
           } else {
               occStart = occStart.add(Duration(days: 7 * custom.interval));
           }
        }
      }
      continue;
    }

    // 期間の数日前（跨ぎ考慮）からチェック開始。時刻を切り落とす
    DateTime checkDate = DateTime(rangeStart.year, rangeStart.month, rangeStart.day)
        .subtract(Duration(days: duration.inDays + 1));
    
    // イベントの開始日以前はチェック不要
    final eventStartDay = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
    if (checkDate.isBefore(eventStartDay)) {
      checkDate = eventStartDay;
    }

    while (checkDate.isBefore(rangeEnd.add(const Duration(seconds: 1)))) {
      bool isMatch = false;
      switch (event.recurrence) {
        case RecurrenceType.daily:
          isMatch = true;
          break;
        case RecurrenceType.weekly:
          isMatch = checkDate.weekday == event.startDate.weekday;
          break;
        case RecurrenceType.monthly:
          isMatch = checkDate.day == event.startDate.day;
          break;
        case RecurrenceType.yearly:
          isMatch = checkDate.month == event.startDate.month && 
                    checkDate.day == event.startDate.day;
          break;
        case RecurrenceType.weekday:
          isMatch = checkDate.weekday >= 1 && checkDate.weekday <= 5;
          if (isMatch && JapaneseHoliday.isHoliday(checkDate)) {
            isMatch = false; // 祝日は除外
          }
          break;
        case RecurrenceType.none:
        case RecurrenceType.custom:
          break;
      }

      if (isMatch) {
        final occurrenceStart = DateTime(
          checkDate.year, checkDate.month, checkDate.day,
          event.startDate.hour, event.startDate.minute,
        );
        final occurrenceEnd = occurrenceStart.add(duration);

        // 期間重複チェック
        if (occurrenceStart.isBefore(rangeEnd) && occurrenceEnd.isAfter(rangeStart)) {
          if (!isExceptionDate(occurrenceStart)) {
            results.add(event.copyWith(
              startDate: occurrenceStart,
              endDate: occurrenceEnd,
            ));
          }
        }
      }

      // 次のチェック日に進む
      if (event.recurrence == RecurrenceType.monthly && isMatch) {
        // 翌月の同日にジャンプ
        checkDate = DateTime(checkDate.year, checkDate.month + 1, checkDate.day);
      } else if (event.recurrence == RecurrenceType.yearly && isMatch) {
        // 翌年の同日にジャンプ
        checkDate = DateTime(checkDate.year + 1, checkDate.month, checkDate.day);
      } else {
        checkDate = checkDate.add(const Duration(days: 1));
      }
      
      // 無限ループ防止（安全策）
      if (checkDate.year > rangeEnd.year + 1) break;
    }
  }
  return results;
}

/// 誕生日データからカレンダー表示用の EventModel を生成するヘルパー。
List<EventModel> _generateBirthdayEvents(
  List<BirthdayModel> birthdays,
  BirthdayDisplaySettings settings,
  DateTime start,
  DateTime end,
) {
  final results = <EventModel>[];
  // 比較のために時刻を切り捨てた開始・終了日
  final rangeStart = DateTime(start.year, start.month, start.day);
  final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

  for (final b in birthdays) {
    // タグによる表示フィルタリング
    bool isExcluded = false;
    if (b.tags.isEmpty) {
      if (settings.excludedTags.contains('')) isExcluded = true;
    } else {
      // 登録されているタグのうち、一つでも除外リストに含まれていれば非表示
      if (b.tags.any((tag) => settings.excludedTags.contains(tag))) {
        isExcluded = true;
      }
    }
    if (isExcluded) continue;

    // 指定レンジ内の各年について、誕生日が該当するかチェック
    for (int year = rangeStart.year; year <= rangeEnd.year; year++) {
      final bDate = DateTime(year, b.date.month, b.date.day);
      
      // 範囲内かチェック
      if (bDate.isAfter(rangeStart.subtract(const Duration(seconds: 1))) &&
          bDate.isBefore(rangeEnd)) {
        
        results.add(EventModel(
          // DBのIDと衝突しないよう、負の値などを使用（仮想イベント）
          id: -(b.id ?? 0) * 10000 - year, 
          title: '🎂 ${b.name}の誕生日',
          startDate: bDate,
          endDate: DateTime(year, b.date.month, b.date.day, 23, 59, 59),
          isAllDay: true,
          colorIndex: EventColor.fromIndex(settings.colorIndex), // 設定色を使用
          isBirthday: true,
        ));
      }
    }
  }
  return results;
}

/// イベント検索結果を提供するProvider。
final eventSearchProvider =
    FutureProvider.family<List<EventModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(eventRepositoryProvider);
  return repository.searchEvents(query);
});

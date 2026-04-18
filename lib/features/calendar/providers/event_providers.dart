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
      final merged = [...events, ...birthdayEvents];
      // 誕生日を優先、その後に開始時刻順でソート
      merged.sort((a, b) {
        if (a.isBirthday && !b.isBirthday) return -1;
        if (!a.isBirthday && b.isBirthday) return 1;
        return a.startDate.compareTo(b.startDate);
      });
      return merged;
    }
    
    return events;
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

    // DBからのイベント取得
    final events = await _repository.getEventsByDateRange(start, end);

    // 誕生日のマージ処理
    final settingsAsync = ref.watch(birthdayDisplaySettingsProvider);
    final birthdaysAsync = ref.watch(birthdayListProvider);
    
    final settings = settingsAsync.valueOrNull;
    final birthdays = birthdaysAsync.valueOrNull;
    
    if (settings != null && settings.isShowOnSchedule && birthdays != null) {
      final birthdayEvents = _generateBirthdayEvents(birthdays, settings, start, end);
      return [...events, ...birthdayEvents];
    }

    return events;
  }

  /// データを強制的に再取得する。
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return build();
    });
  }
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
          endDate: bDate,
          isAllDay: true,
          colorIndex: EventColor.peacock, // 誕生日の標準色（ピーコック）
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

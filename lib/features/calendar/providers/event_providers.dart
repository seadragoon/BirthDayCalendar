import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/repositories/event_repository.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/providers/repository_providers.dart';

/// 選択中の日付に紐づくイベント一覧を提供するProvider。
///
/// [selectedDateProvider] の変更を自動的に監視し、
/// 日付が変わるたびにDBから該当イベントを再取得する。
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
    return _repository.getEventsByDate(selectedDate);
  }

  /// イベントを追加し、リストを再取得する。
  Future<void> addEvent(EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertEvent(event);
      final selectedDate = ref.read(selectedDateProvider);
      return _repository.getEventsByDate(selectedDate);
    });
  }

  /// イベントを更新し、リストを再取得する。
  Future<void> updateEvent(EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateEvent(event);
      final selectedDate = ref.read(selectedDateProvider);
      return _repository.getEventsByDate(selectedDate);
    });
  }

  /// イベントを削除し、リストを再取得する。
  Future<void> deleteEvent(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteEvent(id);
      final selectedDate = ref.read(selectedDateProvider);
      return _repository.getEventsByDate(selectedDate);
    });
  }
}

/// 表示中の月に含まれるイベント一覧を提供するProvider。
///
/// [currentMonthProvider] の変更を自動的に監視し、
/// 月が変わるたびにDBから該当月のイベントを再取得する。
/// カレンダー上のイベントバー表示に使用する。
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

    return _repository.getEventsByDateRange(start, end);
  }

  /// データを強制的に再取得する。
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentMonth = ref.read(currentMonthProvider);
      final start = DateTime(currentMonth.year, currentMonth.month, 1);
      final end = DateTime(currentMonth.year, currentMonth.month + 1, 0);
      return _repository.getEventsByDateRange(start, end);
    });
  }
}

/// イベント検索結果を提供するProvider。
///
/// 検索クエリが空の場合は空リストを返す。
final eventSearchProvider =
    FutureProvider.family<List<EventModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(eventRepositoryProvider);
  return repository.searchEvents(query);
});

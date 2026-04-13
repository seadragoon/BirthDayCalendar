import 'package:calendar_view/calendar_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';

/// `calendar_view` パッケージの [EventController] を提供・管理するProvider。
///
/// Riverpodの [eventsByMonthProvider] の状態変更を監視し、
/// 自動的に [EventController] 内のイベントデータを同期する。
/// これにより、DBのデータ変更が自動的にカレンダーUIに反映される。
final calendarControllerProvider =
    Provider.autoDispose<EventController<EventModel>>((ref) {
  final controller = EventController<EventModel>();

  // eventsByMonthProvider の変更を監視し、EventController と同期
  ref.listen<AsyncValue<List<EventModel>>>(
    eventsByMonthProvider,
    (previous, next) {
      if (next is AsyncData && next.value != null) {
        // 既存のイベントをクリア
        // Note: removeWhere((_) => true) は内部で再描画が走る可能性があるため、
        // 一気にクリアして追加する
        final existingEvents = controller.allEvents.toList();
        for (final e in existingEvents) {
          controller.remove(e);
        }

        // EventModel を CalendarEventData に変換
        final newEvents = next.value!.map((e) {
          return CalendarEventData<EventModel>(
            date: e.startDate,
            endDate: e.endDate,
            event: e,
            title: e.title,
            color: e.colorIndex.color,
            startTime: e.startDate,
            endTime: e.endDate,
          );
        }).toList();

        // コントローラーに追加
        controller.addAll(newEvents);
      }
    },
    fireImmediately: true, // 初回マウント時にも実行
  );

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

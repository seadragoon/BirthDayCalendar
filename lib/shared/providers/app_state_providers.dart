import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/shared/constants/view_type.dart';

/// 現在選択中の日付を管理するProvider。
///
/// カレンダーで日付をタップした際に更新される。
/// 初期値は今日の日付（時刻情報は切り捨て）。
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 現在表示中の月を管理するProvider。
///
/// カレンダーの左右スワイプで更新される。
/// Header のタイトル表示（「2026年4月」等）にも使用する。
final currentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// メインビューの表示タイプ（Schedule / Birthday）を管理するProvider。
///
/// Footer のタブ切り替えで更新される。
/// Header のタイトルやFABの動作もこの値に連動する。
final viewTypeProvider = StateProvider<ViewType>((ref) {
  return ViewType.schedule;
});

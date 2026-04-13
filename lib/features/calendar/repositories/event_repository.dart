import 'package:birthday_calendar/features/calendar/models/event_model.dart';

/// イベント（予定）のデータ操作を定義する抽象クラス。
///
/// UIやProvider層はこのインターフェースを通じてデータにアクセスする。
/// 具体的なデータソース（sqflite等）への依存を排除し、
/// 将来的なデータソースの切り替え（Firebase等）を容易にする。
abstract class EventRepository {
  /// すべてのイベントを取得する。
  Future<List<EventModel>> getAllEvents();

  /// 指定した日付に該当するイベントを取得する。
  ///
  /// 終日イベントおよび、指定日が開始日〜終了日に含まれるイベントを返す。
  Future<List<EventModel>> getEventsByDate(DateTime date);

  /// 指定した日付範囲に該当するイベントを取得する。
  ///
  /// 月間カレンダー表示時に使用。期間内に一部でも重なるイベントを返す。
  Future<List<EventModel>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// 指定したIDのイベントを取得する。
  /// 該当するイベントが無い場合は null を返す。
  Future<EventModel?> getEventById(int id);

  /// イベントを新規に追加する。
  /// 追加したイベントの id を返す。
  Future<int> insertEvent(EventModel event);

  /// 既存のイベントを更新する。
  /// 更新された行数を返す。
  Future<int> updateEvent(EventModel event);

  /// 指定したIDのイベントを削除する。
  /// 削除された行数を返す。
  Future<int> deleteEvent(int id);

  /// タイトルまたはコメントに [query] を含むイベントを検索する。
  Future<List<EventModel>> searchEvents(String query);
}

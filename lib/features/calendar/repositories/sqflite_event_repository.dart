import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/repositories/event_repository.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';

/// [EventRepository] の sqflite 実装クラス。
///
/// [DatabaseHelper] を通じてローカルDBにアクセスし、
/// イベントのCRUD操作を行う。
class SqfliteEventRepository implements EventRepository {
  final DatabaseHelper _dbHelper;

  SqfliteEventRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<EventModel>> getAllEvents() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableEvents,
      orderBy: 'start_date ASC',
    );
    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  @override
  Future<List<EventModel>> getEventsByDate(DateTime date) async {
    // 指定日の 00:00:00 〜 23:59:59 の範囲を計算
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final db = await _dbHelper.database;

    // 以下の条件でイベントを取得:
    // 1. イベントの開始日が指定日内にある
    // 2. イベントの終了日が指定日内にある
    // 3. イベントが指定日を跨いでいる（開始日 <= 指定日 && 終了日 >= 指定日）
    final maps = await db.query(
      DatabaseHelper.tableEvents,
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [
        dayEnd.millisecondsSinceEpoch,
        dayStart.millisecondsSinceEpoch,
      ],
      orderBy: 'is_all_day DESC, start_date ASC',
    );

    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  @override
  Future<List<EventModel>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final db = await _dbHelper.database;

    // 期間内に一部でも重なるイベントを取得
    final maps = await db.query(
      DatabaseHelper.tableEvents,
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [
        rangeEnd.millisecondsSinceEpoch,
        rangeStart.millisecondsSinceEpoch,
      ],
      orderBy: 'is_all_day DESC, start_date ASC',
    );

    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  @override
  Future<EventModel?> getEventById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableEvents,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return EventModel.fromMap(maps.first);
  }

  @override
  Future<int> insertEvent(EventModel event) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // created_at と updated_at を現在時刻で設定
    final eventWithTimestamps = event.copyWith(
      createdAt: now,
      updatedAt: now,
    );

    return await db.insert(
      DatabaseHelper.tableEvents,
      eventWithTimestamps.toMap(),
    );
  }

  @override
  Future<int> updateEvent(EventModel event) async {
    if (event.id == null) {
      throw ArgumentError('更新対象のイベントにIDが設定されていません');
    }

    final db = await _dbHelper.database;
    final now = DateTime.now();

    // updated_at を現在時刻に更新
    final eventWithTimestamp = event.copyWith(updatedAt: now);

    return await db.update(
      DatabaseHelper.tableEvents,
      eventWithTimestamp.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  @override
  Future<int> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableEvents,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<EventModel>> searchEvents(String query) async {
    if (query.isEmpty) return [];

    final db = await _dbHelper.database;
    final searchQuery = '%$query%';

    final maps = await db.query(
      DatabaseHelper.tableEvents,
      where: 'title LIKE ? OR comment LIKE ?',
      whereArgs: [searchQuery, searchQuery],
      orderBy: 'start_date ASC',
    );

    return maps.map((map) => EventModel.fromMap(map)).toList();
  }
}

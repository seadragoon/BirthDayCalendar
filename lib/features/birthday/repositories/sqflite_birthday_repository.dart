import 'dart:convert';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/repositories/birthday_repository.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';

/// [BirthdayRepository] の sqflite 実装クラス。
///
/// [DatabaseHelper] を通じてローカルDBにアクセスし、
/// 誕生日のCRUD操作を行う。
class SqfliteBirthdayRepository implements BirthdayRepository {
  final DatabaseHelper _dbHelper;

  SqfliteBirthdayRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<BirthdayModel>> getAllBirthdays() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableBirthdays,
      orderBy: 'date ASC',
    );
    return maps.map((map) => BirthdayModel.fromMap(map)).toList();
  }

  @override
  Future<List<BirthdayModel>> getBirthdaysByTag(String tag) async {
    final db = await _dbHelper.database;

    // tagsはJSON文字列として保存されているため、LIKE検索で部分一致させる
    // 例: tags = '["家族","友達"]' に対して '%"家族"%' で検索
    final searchTag = '%"$tag"%';
    final maps = await db.query(
      DatabaseHelper.tableBirthdays,
      where: 'tags LIKE ?',
      whereArgs: [searchTag],
      orderBy: 'date ASC',
    );

    return maps.map((map) => BirthdayModel.fromMap(map)).toList();
  }

  @override
  Future<List<BirthdayModel>> getUntaggedBirthdays() async {
    final db = await _dbHelper.database;

    // タグが空リスト（'[]'）または空文字列のものを取得
    final maps = await db.query(
      DatabaseHelper.tableBirthdays,
      where: "tags = '[]' OR tags = '' OR tags IS NULL",
      orderBy: 'date ASC',
    );

    return maps.map((map) => BirthdayModel.fromMap(map)).toList();
  }

  @override
  Future<BirthdayModel?> getBirthdayById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableBirthdays,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BirthdayModel.fromMap(maps.first);
  }

  @override
  Future<int> insertBirthday(BirthdayModel birthday) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // created_at と updated_at を現在時刻で設定
    final birthdayWithTimestamps = birthday.copyWith(
      createdAt: now,
      updatedAt: now,
    );

    return await db.insert(
      DatabaseHelper.tableBirthdays,
      birthdayWithTimestamps.toMap(),
    );
  }

  @override
  Future<int> updateBirthday(BirthdayModel birthday) async {
    if (birthday.id == null) {
      throw ArgumentError('更新対象の誕生日にIDが設定されていません');
    }

    final db = await _dbHelper.database;
    final now = DateTime.now();

    // updated_at を現在時刻に更新
    final birthdayWithTimestamp = birthday.copyWith(updatedAt: now);

    return await db.update(
      DatabaseHelper.tableBirthdays,
      birthdayWithTimestamp.toMap(),
      where: 'id = ?',
      whereArgs: [birthday.id],
    );
  }

  @override
  Future<int> deleteBirthday(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableBirthdays,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<BirthdayModel>> searchBirthdays(String query) async {
    if (query.isEmpty) return [];

    final db = await _dbHelper.database;
    final searchQuery = '%$query%';

    final maps = await db.query(
      DatabaseHelper.tableBirthdays,
      where: 'name LIKE ?',
      whereArgs: [searchQuery],
      orderBy: 'date ASC',
    );

    return maps.map((map) => BirthdayModel.fromMap(map)).toList();
  }

  @override
  Future<List<String>> getAllTags() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableBirthdays,
      columns: ['tags'],
    );

    // 全レコードのタグを集めて重複を除去
    final allTags = <String>{};
    for (final map in maps) {
      final tagsJson = map['tags'] as String?;
      if (tagsJson != null && tagsJson.isNotEmpty && tagsJson != '[]') {
        final decoded = jsonDecode(tagsJson) as List<dynamic>;
        allTags.addAll(decoded.cast<String>());
      }
    }

    return allTags.toList(); // 追加順（LinkedHashSetの順序）を維持
  }
}

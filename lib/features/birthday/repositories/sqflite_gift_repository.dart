import 'package:sqflite/sqflite.dart';
import 'package:birthday_calendar/features/birthday/models/gift_model.dart';
import 'package:birthday_calendar/features/birthday/repositories/gift_repository.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';

/// sqfliteを使用した [GiftRepository] の具象実装クラス。
class SqfliteGiftRepository implements GiftRepository {
  final DatabaseHelper _dbHelper;

  SqfliteGiftRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<GiftModel>> getGiftsByBirthdayId(int birthdayId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableGifts,
      where: 'birthday_id = ?',
      whereArgs: [birthdayId],
      orderBy: 'year DESC, created_at DESC',
    );
    return results.map((map) => GiftModel.fromMap(map)).toList();
  }

  @override
  Future<List<GiftModel>> getAllGifts() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableGifts,
      orderBy: 'birthday_id ASC, year DESC',
    );
    return results.map((map) => GiftModel.fromMap(map)).toList();
  }

  @override
  Future<GiftModel?> getGiftById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableGifts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return GiftModel.fromMap(results.first);
  }

  @override
  Future<int> insertGift(GiftModel gift) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableGifts,
      gift.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateGift(GiftModel gift) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableGifts,
      gift.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [gift.id],
    );
  }

  @override
  Future<int> deleteGift(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableGifts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> deleteGiftsByBirthdayId(int birthdayId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableGifts,
      where: 'birthday_id = ?',
      whereArgs: [birthdayId],
    );
  }
}

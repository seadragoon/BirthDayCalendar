import 'package:birthday_calendar/features/birthday/models/tag_model.dart';
import 'package:birthday_calendar/features/birthday/repositories/tag_repository.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// sqflite を使用した TagRepository の実装クラス。
class SqfliteTagRepository implements TagRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<TagModel>> getAllTags() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTags,
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) => TagModel.fromMap(maps[i]));
  }

  @override
  Future<int> insertTag(String name) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return await db.insert(
      DatabaseHelper.tableTags,
      {
        'name': name,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> deleteTag(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableTags,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

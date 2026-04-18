import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// アプリ全体で使用するsqfliteデータベースのヘルパークラス。
///
/// シングルトンパターンで [Database] インスタンスを管理する。
/// `events` テーブルと `birthdays` テーブルを作成・管理する。
class DatabaseHelper {
  // シングルトンインスタンス
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  /// データベース名
  static const String _databaseName = 'birthday_calendar.db';

  /// データベースバージョン（スキーマ変更時にインクリメント）
  static const int _databaseVersion = 5;

  // テーブル名
  static const String tableEvents = 'events';
  static const String tableBirthdays = 'birthdays';
  static const String tableTags = 'tags';

  /// データベースインスタンスを取得する。
  /// 初回アクセス時に自動的にDBファイルを作成する。
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  /// データベースを初期化する。
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// テーブルを作成する。
  Future<void> _createDB(Database db, int version) async {
    // events テーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableEvents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        is_all_day INTEGER NOT NULL DEFAULT 0,
        color_index INTEGER NOT NULL DEFAULT 6,
        recurrence INTEGER NOT NULL DEFAULT 0,
        notification TEXT NOT NULL DEFAULT '[0]',
        comment TEXT DEFAULT '',
        is_birthday INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // birthdays テーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBirthdays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date INTEGER NOT NULL,
        is_year_unknown INTEGER NOT NULL DEFAULT 0,
        tags TEXT DEFAULT '[]',
        notification TEXT NOT NULL DEFAULT '[0]',
        comment TEXT DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // tags テーブル (Version 3 追加)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');

    // インデックスの作成（日付での検索を高速化）
    await db.execute('''
      CREATE INDEX idx_events_start_date ON $tableEvents (start_date)
    ''');
    await db.execute('''
      CREATE INDEX idx_events_end_date ON $tableEvents (end_date)
    ''');
    await db.execute('''
      CREATE INDEX idx_birthdays_date ON $tableBirthdays (date)
    ''');

    // 初期データの投入 (Version 4 以降)
    await _seedTags(db);
  }

  /// データベースのアップグレード処理。
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // notification カラムを INTEGER から TEXT に変更するためのマイグレーション

      // 1. 既存テーブルのリネーム
      await db.execute('ALTER TABLE $tableEvents RENAME TO events_old');
      await db.execute('ALTER TABLE $tableBirthdays RENAME TO birthdays_old');

      // 2. 新しいスキーマでテーブル作成
      await _createDB(db, newVersion);

      // 3. データ移行 (INTEGER を JSON形式の文字列 "[x]" に変換)
      await db.execute('''
        INSERT INTO $tableEvents (id, title, start_date, end_date, is_all_day, color_index, recurrence, notification, comment, is_birthday, created_at, updated_at)
        SELECT id, title, start_date, end_date, is_all_day, color_index, recurrence, '[' || notification || ']', comment, is_birthday, created_at, updated_at
        FROM events_old
      ''');

      await db.execute('''
        INSERT INTO $tableBirthdays (id, name, date, is_year_unknown, tags, notification, created_at, updated_at)
        SELECT id, name, date, is_year_unknown, tags, '[' || notification || ']', created_at, updated_at
        FROM birthdays_old
      ''');

      // 4. 旧テーブルの削除
      await db.execute('DROP TABLE events_old');
      await db.execute('DROP TABLE birthdays_old');
    }

    if (oldVersion < 3) {
      // tags テーブルの追加
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableTags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          created_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // 初期データの投入 (v3で登録に失敗した可能性があるため、v4でも実行)
      await _seedTags(db);
    }

    if (oldVersion < 5) {
      // birthdays テーブルに comment カラムを追加
      await db.execute('ALTER TABLE $tableBirthdays ADD COLUMN comment TEXT DEFAULT ""');
    }
  }

  /// 初期タグの投入
  Future<void> _seedTags(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      tableTags,
      {'name': '家族', 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.insert(
      tableTags,
      {'name': '友人', 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// データベースを閉じる。
  /// アプリ終了時やテスト時に使用。
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}

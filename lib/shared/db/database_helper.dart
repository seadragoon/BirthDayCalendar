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
  static const int _databaseVersion = 1;

  // テーブル名
  static const String tableEvents = 'events';
  static const String tableBirthdays = 'birthdays';

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
      CREATE TABLE $tableEvents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        is_all_day INTEGER NOT NULL DEFAULT 0,
        color_index INTEGER NOT NULL DEFAULT 6,
        recurrence INTEGER NOT NULL DEFAULT 0,
        notification INTEGER NOT NULL DEFAULT 0,
        comment TEXT DEFAULT '',
        is_birthday INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // birthdays テーブル
    await db.execute('''
      CREATE TABLE $tableBirthdays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date INTEGER NOT NULL,
        is_year_unknown INTEGER NOT NULL DEFAULT 0,
        tags TEXT DEFAULT '[]',
        notification INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
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
  }

  /// データベースのアップグレード処理。
  /// 将来のスキーマ変更時にマイグレーションロジックを追加する。
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 将来のバージョンアップ時にマイグレーション処理を追加
    // 例:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $tableEvents ADD COLUMN location TEXT');
    // }
  }

  /// データベースを閉じる。
  /// アプリ終了時やテスト時に使用。
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}

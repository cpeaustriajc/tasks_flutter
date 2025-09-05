import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabaseSingleton {
  AppDatabaseSingleton._();

  static final AppDatabaseSingleton instance = AppDatabaseSingleton._();

  static const _databaseName = 'tasks.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();

    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );

    return _database!;
  }

  Future<void> _onCreate(Database database, int version) async {
    await database.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await database.execute('''
        ALTER TABLE tasks ADD COLUMN imagePath TEXT
      ''');
    }
  }

  Future<void> _onOpen(Database db) async {
    // Ensure column exists even if version bump was missed earlier
    final rows = await db.rawQuery('PRAGMA table_info(tasks)');
    final hasImagePath = rows.any((r) => r['name'] == 'imagePath');
    if (!hasImagePath) {
      await db.execute('ALTER TABLE tasks ADD COLUMN imagePath TEXT');
    }
  }
}

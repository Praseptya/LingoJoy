import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/practice_result_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();

  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('speech_learning_app.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE practice_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        category TEXT NOT NULL,
        recognized_word TEXT NOT NULL,
        distance INTEGER NOT NULL,
        score INTEGER NOT NULL,
        feedback TEXT NOT NULL,
        asr_method TEXT NOT NULL DEFAULT 'Google ASR',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          "ALTER TABLE practice_results ADD COLUMN asr_method TEXT NOT NULL DEFAULT 'Google ASR'",
        );
      } catch (error) {
        final message = error.toString().toLowerCase();
        if (!message.contains('duplicate column') &&
            !message.contains('duplicate column name')) {
          rethrow;
        }
      }
    }
  }

  Future<int> insertPracticeResult(PracticeResult result) async {
    final db = await instance.database;

    return await db.insert('practice_results', result.toMap());
  }

  Future<List<PracticeResult>> getAllPracticeResults() async {
    final db = await instance.database;

    final result = await db.query('practice_results', orderBy: 'id DESC');

    return result.map((map) => PracticeResult.fromMap(map)).toList();
  }

  Future<int> getPerfectPracticeCount() async {
    final db = await instance.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM practice_results WHERE score = 100',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteAllPracticeResults() async {
    final db = await instance.database;

    return await db.delete('practice_results');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}

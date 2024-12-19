import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  factory DatabaseHelper() {
    return _instance;
  }

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scores.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE scores (
  id $idType,
  playerName $textType,
  score $integerType
)
''');
  }

  Future<void> insertScore(String playerName, int score) async {
    final db = await instance.database;

    final data = {'playerName': playerName, 'score': score};
    await db.insert('scores', data);
  }

  Future<List<Map<String, dynamic>>> getScores() async {
    final db = await instance.database;

    return await db.query('scores');
  }
}

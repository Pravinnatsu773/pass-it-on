import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Create Tasks Table
    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textType,
        isCompleted $boolType,
        updatedAt $textType
      )
    ''');

    // Create Sync Queue Table (tracks offline mutations)
    await db.execute('''
      CREATE TABLE sync_queue (
        id $idType, -- Typically a UUID for the queue entry
        entityId $textType, -- The ID of the task/item being mutated
        collectionName $textType, -- e.g., 'tasks'
        operation $textType, -- 'CREATE', 'UPDATE', 'DELETE'
        payload $textType, -- JSON representation of the data
        timestamp $integerType -- Used to process queue in order
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

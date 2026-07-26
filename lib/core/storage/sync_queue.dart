import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'local_database.dart';

enum SyncOperation { create, update, delete }

class SyncQueue {
  final LocalDatabase _dbInstance = LocalDatabase.instance;

  Future<void> addToQueue({
    required String entityId,
    required String collectionName,
    required SyncOperation operation,
    required String payload,
  }) async {
    final db = await _dbInstance.database;
    
    await db.insert(
      'sync_queue',
      {
        'id': const Uuid().v4(),
        'entityId': entityId,
        'collectionName': collectionName,
        'operation': operation.name.toUpperCase(),
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final db = await _dbInstance.database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> removeFromQueue(String id) async {
    final db = await _dbInstance.database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

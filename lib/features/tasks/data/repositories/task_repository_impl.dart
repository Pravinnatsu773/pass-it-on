import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/storage/sync_queue.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final ConnectivityProvider connectivityProvider;
  final SyncQueue syncQueue;

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityProvider,
    required this.syncQueue,
  });

  @override
  Stream<List<Task>> getTasksStream() {
    // 1. Immediately return the local stream so UI is fast and reactive
    final localStream = localDataSource.getTasksStream();

    // 2. Asynchronously fetch from remote if online
    if (connectivityProvider.isOnline) {
      _syncRemoteToLocal();
    }

    return localStream;
  }

  Future<void> _syncRemoteToLocal() async {
    try {
      final remoteTasks = await remoteDataSource.fetchTasks();
      // Update local database with fresh remote data. 
      // Because localDataSource.getTasksStream() is listening to SQLite,
      // the UI will automatically update when this completes.
      await localDataSource.cacheTasks(remoteTasks);
    } catch (e) {
      debugPrint('Background sync failed: $e');
      // Do nothing, UI still has local data
    }
  }

  @override
  Future<void> addTask(Task task) async {
    final taskModel = TaskModel(
      id: task.id,
      title: task.title,
      isCompleted: task.isCompleted,
      updatedAt: task.updatedAt,
    );

    // 1. ALWAYS write to local database FIRST
    await localDataSource.addTask(taskModel);

    // 2. Handle remote sync
    if (connectivityProvider.isOnline) {
      try {
        await remoteDataSource.addTask(taskModel);
      } catch (e) {
        // Fallback: if Firebase fails despite network, queue it
        await _queueMutation(taskModel, SyncOperation.create);
      }
    } else {
      // 3. Offline: Add to Sync Queue
      await _queueMutation(taskModel, SyncOperation.create);
    }
  }

  Future<void> _queueMutation(TaskModel task, SyncOperation operation) async {
    await syncQueue.addToQueue(
      entityId: task.id,
      collectionName: 'tasks',
      operation: operation,
      payload: jsonEncode(task.toJson()),
    );
  }
}

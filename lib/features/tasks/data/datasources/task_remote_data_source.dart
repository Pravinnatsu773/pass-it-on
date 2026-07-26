import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> fetchTasks();
  Future<void> addTask(TaskModel task);
}

import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Stream<List<TaskModel>> getTasksStream();
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<void> addTask(TaskModel task);
}

import '../entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> getTasksStream();
  Future<void> addTask(Task task);
}

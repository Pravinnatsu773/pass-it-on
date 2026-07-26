
import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.isCompleted,
    required super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] == 1 || json['isCompleted'] == true,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0, // SQLite prefers integers for booleans
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

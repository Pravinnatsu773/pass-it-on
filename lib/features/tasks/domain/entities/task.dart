class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.updatedAt,
  });
}

class TaskModel {
  final int id;
  final String title;
  final String description;
  final bool isCompleted;

  TaskModel({
    int? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

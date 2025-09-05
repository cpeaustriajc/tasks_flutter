class TaskModel {
  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final String? imagePath;

  TaskModel({
    int? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.imagePath,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? imagePath,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    isCompleted: map['isCompleted'] == 1,
    imagePath: map['imagePath'] as String?,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'imagePath': imagePath,
    };
  }
}

class ChatModel {
  final String id;
  final String uid;
  final String? name;
  final String text;
  final int ts;

  ChatModel({
    required this.id,
    required this.uid,
    required this.text,
    required this.ts,
    this.name,
  });

  factory ChatModel.fromMap(Map<dynamic, dynamic> data, {String? id}) {
    return ChatModel(
      id: id ?? (data['id']?.toString() ?? ''),
      uid: data['uid']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      name: data['name']?.toString(),
      ts: _asInt(data['ts']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }
}

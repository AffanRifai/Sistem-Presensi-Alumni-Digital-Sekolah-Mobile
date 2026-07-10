class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.payload,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notifikasi',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'notification',
      payload: _readPayload(json['payload']),
      readAt: _readDate(json['read_at']),
      createdAt: _readDate(json['created_at']),
    );
  }

  static Map<String, dynamic> _readPayload(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static DateTime? _readDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }
}

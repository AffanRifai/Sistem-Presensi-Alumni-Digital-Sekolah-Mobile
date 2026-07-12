class ScheduleItem {
  final int id;
  final String day;
  final String room;
  final String startTime;
  final String endTime;
  final String className;
  final String subjectName;

  ScheduleItem({
    required this.id,
    required this.day,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.className,
    required this.subjectName,
  });

  static String _parseTime(dynamic timeData) {
    if (timeData == null) return '--:--';
    final str = timeData.toString();
    if (str.length >= 5) {
      return str.substring(0, 5);
    }
    return str.isEmpty ? '--:--' : str;
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final classHour = json['class_hour'] ?? json['classHour'] ?? {};
    final classData = json['class'] ?? {};
    final subjectData = json['subject'] ?? {};

    return ScheduleItem(
      id: json['id'] ?? 0,
      day: json['day'] ?? '',
      room: json['room'] ?? '-',
      startTime: _parseTime(classHour['start_time']),
      endTime: _parseTime(classHour['end_time']),
      className: classData['name'] ?? 'Tanpa Kelas',
      subjectName: subjectData['name'] ?? 'Tanpa Mapel',
    );
  }
}

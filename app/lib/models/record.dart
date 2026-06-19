/// 一次"起飞"打卡
class FlightRecord {
  final int id;
  final int userId;
  final DateTime time;
  final String note;
  final DateTime? createdAt;

  const FlightRecord({
    required this.id,
    required this.userId,
    required this.time,
    this.note = '',
    this.createdAt,
  });

  factory FlightRecord.fromJson(Map<String, dynamic> json) => FlightRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        time: DateTime.parse(json['time'] as String).toLocal(),
        note: json['note'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String).toLocal()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'time': time.toUtc().toIso8601String(),
        'note': note,
        if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      };
}

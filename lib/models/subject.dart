class Subject {
  String id;
  String name;
  int weeklyHours;
  bool preferConsecutive;
  int maxConsecutiveHours;
  int maxDailyHours;
  DateTime createdAt;
  DateTime updatedAt;

  Subject({
    required this.id,
    required this.name,
    required this.weeklyHours,
    required this.preferConsecutive,
    required this.maxConsecutiveHours,
    required this.maxDailyHours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'],
        name: json['name'],
        weeklyHours: json['weekly_hours'],
        preferConsecutive: json['prefer_consecutive'] ?? false,
        maxConsecutiveHours: json['max_consecutive_hours'] ?? 2,
        maxDailyHours: json['max_daily_hours'] ?? 2,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weekly_hours': weeklyHours,
        'prefer_consecutive': preferConsecutive,
        'max_consecutive_hours': maxConsecutiveHours,
        'max_daily_hours': maxDailyHours,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

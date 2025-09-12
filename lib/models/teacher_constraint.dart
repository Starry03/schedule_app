class TeacherConstraint {
  String id;
  String teacherId;
  int dayOfWeek;
  int hourSlot;
  DateTime createdAt;

  TeacherConstraint({
    required this.id,
    required this.teacherId,
    required this.dayOfWeek,
    required this.hourSlot,
    required this.createdAt,
  });

  factory TeacherConstraint.fromJson(Map<String, dynamic> json) => TeacherConstraint(
        id: json['id'],
        teacherId: json['teacher_id'],
        dayOfWeek: json['day_of_week'],
        hourSlot: json['hour_slot'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'day_of_week': dayOfWeek,
        'hour_slot': hourSlot,
        'created_at': createdAt.toIso8601String(),
      };
}

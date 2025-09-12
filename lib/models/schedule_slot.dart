class ScheduleSlot {
  String id;
  String scheduleId;
  String teacherId;
  String subjectId;
  String classId;
  int dayOfWeek;
  int hourSlot;
  DateTime createdAt;

  ScheduleSlot({
    required this.id,
    required this.scheduleId,
    required this.teacherId,
    required this.subjectId,
    required this.classId,
    required this.dayOfWeek,
    required this.hourSlot,
    required this.createdAt,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        id: json['id'],
        scheduleId: json['schedule_id'],
        teacherId: json['teacher_id'],
        subjectId: json['subject_id'],
        classId: json['class_id'],
        dayOfWeek: json['day_of_week'],
        hourSlot: json['hour_slot'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'schedule_id': scheduleId,
        'teacher_id': teacherId,
        'subject_id': subjectId,
        'class_id': classId,
        'day_of_week': dayOfWeek,
        'hour_slot': hourSlot,
        'created_at': createdAt.toIso8601String(),
      };
}

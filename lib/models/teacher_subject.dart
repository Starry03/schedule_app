class TeacherSubject {
  String id;
  String teacherId;
  String subjectId;
  String classId;
  DateTime createdAt;

  TeacherSubject({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.classId,
    required this.createdAt,
  });

  factory TeacherSubject.fromJson(Map<String, dynamic> json) => TeacherSubject(
        id: json['id'],
        teacherId: json['teacher_id'],
        subjectId: json['subject_id'],
        classId: json['class_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'subject_id': subjectId,
        'class_id': classId,
        'created_at': createdAt.toIso8601String(),
      };
}

class ClassModel {
  String id;
  String name;
  int grade;
  String section;
  DateTime createdAt;
  DateTime updatedAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        id: json['id'],
        name: json['name'],
        grade: json['grade'],
        section: json['section'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'section': section,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

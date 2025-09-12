class Teacher {
  String id;
  String name;
  String? email;
  DateTime createdAt;
  DateTime updatedAt;
  int extraHours;

  Teacher({
    required this.id,
    required this.name,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    this.extraHours = 0,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        extraHours: json['extra_hours'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'extra_hours': extraHours,
      };
}

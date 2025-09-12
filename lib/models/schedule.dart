class Schedule {
  String id;
  String name;
  int generationSeed;
  DateTime createdAt;
  DateTime updatedAt;

  Schedule({
    required this.id,
    required this.name,
    required this.generationSeed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        id: json['id'],
        name: json['name'],
        generationSeed: json['generation_seed'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'generation_seed': generationSeed,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  // Per gli INSERT - NON include l'id
  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'generation_seed': generationSeed,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Schedule copyWith({
    String? id,
    String? name,
    int? generationSeed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      generationSeed: generationSeed ?? this.generationSeed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

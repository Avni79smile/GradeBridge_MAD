class Batch {
  final String id;
  final String name;
  final String className;
  final String description;
  final DateTime createdAt;

  Batch({
    required this.id,
    required this.name,
    required this.className,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'className': className,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'],
      name: json['name'],
      className: json['className'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Batch copyWith({String? name, String? className, String? description}) {
    return Batch(
      id: id,
      name: name ?? this.name,
      className: className ?? this.className,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'name': name,
    'class_name': className,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };

  factory Batch.fromSupabase(Map<String, dynamic> row) => Batch(
    id: row['id'],
    name: row['name'],
    className: row['class_name'],
    description: row['description'] ?? '',
    createdAt: DateTime.parse(row['created_at']),
  );
}

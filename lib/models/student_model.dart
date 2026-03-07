class Student {
  final String id;
  final String batchId;
  final String name;
  final String rollNumber;
  final String email;
  final String phone;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.batchId,
    required this.name,
    required this.rollNumber,
    this.email = '',
    this.phone = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      batchId: json['batchId'],
      name: json['name'],
      rollNumber: json['rollNumber'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Student copyWith({
    String? name,
    String? rollNumber,
    String? email,
    String? phone,
  }) {
    return Student(
      id: id,
      batchId: batchId,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'batch_id': batchId,
    'name': name,
    'roll_number': rollNumber,
    'email': email,
    'phone': phone,
    'created_at': createdAt.toIso8601String(),
  };

  factory Student.fromSupabase(Map<String, dynamic> row) => Student(
    id: row['id'],
    batchId: row['batch_id'],
    name: row['name'],
    rollNumber: row['roll_number'],
    email: row['email'] ?? '',
    phone: row['phone'] ?? '',
    createdAt: DateTime.parse(row['created_at']),
  );
}

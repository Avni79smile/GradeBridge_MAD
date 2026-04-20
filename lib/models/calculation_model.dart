class Subject {
  final String name;
  final double score;
  final double outOf;
  final double credit;

  Subject({
    required this.name,
    required this.score,
    required this.outOf,
    required this.credit,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'score': score, 'outOf': outOf, 'credit': credit};
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      name: map['name'] ?? '',
      score: map['score'] ?? 0.0,
      outOf: map['outOf'] ?? 100.0,
      credit: map['credit'] ?? 0.0,
    );
  }
}

class CalculationRecord {
  final int? id;
  final String calculationType; // 'CGPA' or 'SGPA'
  final double result;
  final List<Subject> subjects;
  final DateTime timestamp;
  final String semesterName;

  CalculationRecord({
    this.id,
    required this.calculationType,
    required this.result,
    required this.subjects,
    required this.timestamp,
    required this.semesterName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'calculationType': calculationType,
      'result': result,
      'subjects': subjects.map((s) => s.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'semesterName': semesterName,
    };
  }

  factory CalculationRecord.fromMap(Map<String, dynamic> map) {
    return CalculationRecord(
      id: map['id'] as int?,
      calculationType: map['calculationType'] ?? 'CGPA',
      result: (map['result'] as num?)?.toDouble() ?? 0.0,
      subjects:
          (map['subjects'] as List<dynamic>?)
              ?.map((s) => Subject.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      semesterName: map['semesterName'] ?? 'Unknown',
    );
  }
}

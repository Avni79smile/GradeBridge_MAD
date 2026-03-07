class StudentSubject {
  final String id;
  final String name;
  final int credits;
  final String grade;
  final double gradePoints;

  StudentSubject({
    String? id,
    required this.name,
    required this.credits,
    required this.grade,
    required this.gradePoints,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'credits': credits,
      'grade': grade,
      'gradePoints': gradePoints,
    };
  }

  factory StudentSubject.fromJson(Map<String, dynamic> json) {
    return StudentSubject(
      id: json['id'],
      name: json['name'],
      credits: json['credits'],
      grade: json['grade'],
      gradePoints: (json['gradePoints'] as num).toDouble(),
    );
  }
}

class StudentSemester {
  final String id;
  final String semesterName;
  final List<StudentSubject> subjects;
  final double sgpa;
  final DateTime createdAt;

  /// Which calculator was used to create this semester: 'sgpa' or 'cgpa'
  final String toolUsed;

  StudentSemester({
    String? id,
    String? semesterName,
    required this.subjects,
    required this.sgpa,
    DateTime? createdAt,
    String? toolUsed,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       semesterName = semesterName ?? '',
       createdAt = createdAt ?? DateTime.now(),
       toolUsed = toolUsed ?? 'sgpa';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterName': semesterName,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'sgpa': sgpa,
      'createdAt': createdAt.toIso8601String(),
      'toolUsed': toolUsed,
    };
  }

  factory StudentSemester.fromJson(Map<String, dynamic> json) {
    return StudentSemester(
      id: json['id'],
      semesterName: json['semesterName'],
      subjects: (json['subjects'] as List)
          .map((s) => StudentSubject.fromJson(s))
          .toList(),
      sgpa: (json['sgpa'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      toolUsed: (json['toolUsed'] as String?) ?? 'sgpa',
    );
  }

  StudentSemester copyWith({
    String? semesterName,
    List<StudentSubject>? subjects,
    double? sgpa,
    String? toolUsed,
  }) {
    return StudentSemester(
      id: id,
      semesterName: semesterName ?? this.semesterName,
      subjects: subjects ?? this.subjects,
      sgpa: sgpa ?? this.sgpa,
      createdAt: createdAt,
      toolUsed: toolUsed ?? this.toolUsed,
    );
  }

  int get totalCredits => subjects.fold(0, (sum, s) => sum + s.credits);
}

class StudentGradeData {
  final String studentId;
  final List<StudentSemester> semesters;
  final double cgpa;
  final DateTime lastUpdated;

  StudentGradeData({
    required this.studentId,
    this.semesters = const [],
    this.cgpa = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'semesters': semesters.map((s) => s.toJson()).toList(),
      'cgpa': cgpa,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory StudentGradeData.fromJson(Map<String, dynamic> json) {
    return StudentGradeData(
      studentId: json['studentId'],
      semesters:
          (json['semesters'] as List?)
              ?.map((s) => StudentSemester.fromJson(s))
              .toList() ??
          [],
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  StudentGradeData copyWith({List<StudentSemester>? semesters, double? cgpa}) {
    return StudentGradeData(
      studentId: studentId,
      semesters: semesters ?? this.semesters,
      cgpa: cgpa ?? this.cgpa,
      lastUpdated: DateTime.now(),
    );
  }

  int get totalCredits =>
      semesters.fold(0, (sum, sem) => sum + sem.totalCredits);

  int get totalSemesters => semesters.length;
}

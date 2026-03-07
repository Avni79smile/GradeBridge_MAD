import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_grade_model.dart';

class StudentGradeProvider extends ChangeNotifier {
  Map<String, StudentGradeData> _gradeDataMap = {};
  bool _isInitialized = false;

  Map<String, StudentGradeData> get gradeDataMap => _gradeDataMap;
  bool get isInitialized => _isInitialized;

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> init() async {
    if (_isInitialized) return;
    await _loadAllGradeData();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadAllGradeData() async {
    try {
      final data = await _db.from('student_grades').select();
      for (final row in (data as List)) {
        final gradeData = StudentGradeData.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        _gradeDataMap[gradeData.studentId] = gradeData;
      }
    } catch (e) {
      debugPrint('Error loading grade data: $e');
    }
  }

  StudentGradeData? getGradeData(String studentId) {
    return _gradeDataMap[studentId];
  }

  StudentGradeData getOrCreateGradeData(String studentId) {
    if (_gradeDataMap.containsKey(studentId)) {
      return _gradeDataMap[studentId]!;
    }
    final newData = StudentGradeData(studentId: studentId);
    _gradeDataMap[studentId] = newData;
    return newData;
  }

  Future<void> saveGradeData(StudentGradeData gradeData) async {
    _gradeDataMap[gradeData.studentId] = gradeData;

    try {
      final teacherId = _db.auth.currentUser?.id;
      if (teacherId != null) {
        await _db.from('student_grades').upsert({
          'student_id': gradeData.studentId,
          'teacher_id': teacherId,
          'data': gradeData.toJson(),
          'last_updated': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error saving grade data: $e');
    }

    notifyListeners();
  }

  Future<void> addSemester(String studentId, StudentSemester semester) async {
    final gradeData = getOrCreateGradeData(studentId);
    final updatedSemesters = [...gradeData.semesters, semester];
    final cgpa = _calculateCGPA(updatedSemesters);

    final updatedData = gradeData.copyWith(
      semesters: updatedSemesters,
      cgpa: cgpa,
    );

    await saveGradeData(updatedData);
  }

  Future<void> updateSemester(
    String studentId,
    StudentSemester semester,
  ) async {
    final gradeData = getOrCreateGradeData(studentId);
    final updatedSemesters = gradeData.semesters.map((s) {
      return s.id == semester.id ? semester : s;
    }).toList();
    final cgpa = _calculateCGPA(updatedSemesters);

    final updatedData = gradeData.copyWith(
      semesters: updatedSemesters,
      cgpa: cgpa,
    );

    await saveGradeData(updatedData);
  }

  /// Appends [newSubjects] to an existing semester and recalculates its SGPA.
  Future<void> appendSubjectsToSemester(
    String studentId,
    String semesterId,
    List<StudentSubject> newSubjects,
  ) async {
    final gradeData = getOrCreateGradeData(studentId);
    final idx = gradeData.semesters.indexWhere((s) => s.id == semesterId);
    if (idx == -1) return;

    final existing = gradeData.semesters[idx];
    final merged = [...existing.subjects, ...newSubjects];
    final sgpa = calculateSGPA(merged);

    await updateSemester(
      studentId,
      existing.copyWith(subjects: merged, sgpa: sgpa),
    );
  }

  Future<void> deleteSemester(String studentId, String semesterId) async {
    final gradeData = getOrCreateGradeData(studentId);
    final updatedSemesters = gradeData.semesters
        .where((s) => s.id != semesterId)
        .toList();
    final cgpa = _calculateCGPA(updatedSemesters);

    final updatedData = gradeData.copyWith(
      semesters: updatedSemesters,
      cgpa: cgpa,
    );

    await saveGradeData(updatedData);
  }

  Future<void> deleteStudentGradeData(String studentId) async {
    _gradeDataMap.remove(studentId);

    try {
      await _db.from('student_grades').delete().eq('student_id', studentId);
    } catch (e) {
      debugPrint('Error deleting grade data: $e');
    }

    notifyListeners();
  }

  double _calculateCGPA(List<StudentSemester> semesters) {
    if (semesters.isEmpty) return 0.0;

    double totalPoints = 0;
    int totalCredits = 0;

    for (var semester in semesters) {
      for (var subject in semester.subjects) {
        totalPoints += subject.gradePoints * subject.credits;
        totalCredits += subject.credits;
      }
    }

    if (totalCredits == 0) return 0.0;
    return totalPoints / totalCredits;
  }

  double calculateSGPA(List<StudentSubject> subjects) {
    if (subjects.isEmpty) return 0.0;

    double totalPoints = 0;
    int totalCredits = 0;

    for (var subject in subjects) {
      totalPoints += subject.gradePoints * subject.credits;
      totalCredits += subject.credits;
    }

    if (totalCredits == 0) return 0.0;
    return totalPoints / totalCredits;
  }
}

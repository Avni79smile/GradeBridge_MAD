import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_grade_model.dart';

class StudentGradeProvider extends ChangeNotifier {
  Map<String, StudentGradeData> _gradeDataMap = {};
  bool _isInitialized = false;
  bool _isLoadingData = false;

  /// Grade data assigned by teacher for the currently logged-in student.
  StudentGradeData? _myTeacherGradeData;
  bool _isLoadingTeacherGrades = false;

  Map<String, StudentGradeData> get gradeDataMap => _gradeDataMap;
  bool get isInitialized => _isInitialized;
  bool get isLoadingData => _isLoadingData;
  StudentGradeData? get myTeacherGradeData => _myTeacherGradeData;
  bool get isLoadingTeacherGrades => _isLoadingTeacherGrades;

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> init() async {
    if (_isInitialized) return;
    final loaded = await _loadAllGradeData();
    if (loaded) _isInitialized = true;
    notifyListeners();
  }

  /// Force a fresh fetch from Supabase. Call when opening grade-related pages.
  Future<void> reloadFromDatabase() async {
    _isInitialized = false;
    _isLoadingData = true;
    notifyListeners();
    final loaded = await _loadAllGradeData();
    if (loaded) _isInitialized = true;
    _isLoadingData = false;
    notifyListeners();
  }

  Future<bool> _loadAllGradeData() async {
    // Retry up to 3 times with increasing delays to handle cold-start network
    // issues (especially on Flutter Web / Chrome where fetch can fail briefly).
    const delays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ];
    for (int attempt = 0; attempt <= delays.length; attempt++) {
      try {
        final data = await _db.from('student_grades').select();
        for (final row in (data as List)) {
          try {
            final gradeData = StudentGradeData.fromJson(
              Map<String, dynamic>.from(row['data'] as Map),
            );
            _gradeDataMap[gradeData.studentId] = gradeData;
          } catch (rowErr) {
            debugPrint('Skipping malformed grade row: $rowErr');
          }
        }
        return true;
      } catch (e) {
        debugPrint('Error loading grade data (attempt ${attempt + 1}): $e');
        if (attempt < delays.length) {
          await Future.delayed(delays[attempt]);
        }
      }
    }
    return false;
  }

  /// Called when a STUDENT user logs in. Looks up their email in the `students`
  /// table and fetches any grade data the teacher has entered for them.
  Future<void> loadMyTeacherGrades(String email) async {
    if (email.isEmpty) return;
    _isLoadingTeacherGrades = true;
    notifyListeners();

    try {
      // Find the student record that matches this user's email (set by teacher).
      final studentRows = await _db
          .from('students')
          .select('id')
          .eq('email', email)
          .limit(1);

      if ((studentRows as List).isEmpty) {
        _myTeacherGradeData = null;
        _isLoadingTeacherGrades = false;
        notifyListeners();
        return;
      }

      final studentId = studentRows.first['id'] as String;

      // Fetch grade data saved by teacher for this student.
      final gradeRows = await _db
          .from('student_grades')
          .select('data, last_updated')
          .eq('student_id', studentId)
          .limit(1);

      if ((gradeRows as List).isEmpty) {
        _myTeacherGradeData = null;
      } else {
        _myTeacherGradeData = StudentGradeData.fromJson(
          Map<String, dynamic>.from(gradeRows.first['data'] as Map),
        );
        _gradeDataMap[_myTeacherGradeData!.studentId] = _myTeacherGradeData!;
      }
    } catch (e) {
      debugPrint('Error loading teacher grades for student: $e');
      _myTeacherGradeData = null;
    }

    _isLoadingTeacherGrades = false;
    notifyListeners();
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

  /// Fetches this student's grade data from Supabase if it is not already in
  /// the in-memory map.  Must be awaited before any write operation so that we
  /// never overwrite existing semesters with a freshly-created empty record.
  Future<void> _ensureStudentLoaded(String studentId) async {
    if (_gradeDataMap.containsKey(studentId)) return;
    try {
      final rows = await _db
          .from('student_grades')
          .select('data')
          .eq('student_id', studentId)
          .limit(1);
      if ((rows as List).isNotEmpty) {
        final gradeData = StudentGradeData.fromJson(
          Map<String, dynamic>.from(rows.first['data'] as Map),
        );
        _gradeDataMap[gradeData.studentId] = gradeData;
      }
    } catch (e) {
      debugPrint('_ensureStudentLoaded error for $studentId: $e');
    }
  }

  Future<bool> saveGradeData(StudentGradeData gradeData) async {
    _gradeDataMap[gradeData.studentId] = gradeData;
    notifyListeners();

    final currentUser = _db.auth.currentUser;
    final role = currentUser?.userMetadata?['role'] as String?;

    // Both teacher and student should be able to save their grade data.
    if (role != 'teacher' && role != 'student') {
      debugPrint(
        'saveGradeData: only teacher or student can save grades, current role: $role',
      );
      return false;
    }

    try {
      final userId = currentUser?.id;
      if (userId == null) {
        debugPrint(
          'saveGradeData: no authenticated user — skipping Supabase write',
        );
        return false;
      }

      await _db.from('student_grades').upsert({
        'student_id': gradeData.studentId,
        'teacher_id': userId,
        'data': gradeData.toJson(),
        'last_updated': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving grade data: $e');
      return false;
    }
  }

  Future<void> addSemester(String studentId, StudentSemester semester) async {
    await _ensureStudentLoaded(studentId);
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
    await _ensureStudentLoaded(studentId);
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
    await _ensureStudentLoaded(studentId);
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
    await _ensureStudentLoaded(studentId);
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentProvider extends ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  SupabaseClient get _db => Supabase.instance.client;

  StudentProvider() {
    loadStudents();
  }

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _db.from('students').select().order('created_at');
      _students = (data as List).map((e) => Student.fromSupabase(e)).toList();
    } catch (e) {
      debugPrint('Error loading students: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Student> getStudentsByBatchId(String batchId) {
    return _students.where((s) => s.batchId == batchId).toList();
  }

  int getStudentCountForBatch(String batchId) {
    return _students.where((s) => s.batchId == batchId).length;
  }

  Future<void> addStudent({
    required String batchId,
    required String name,
    required String rollNumber,
    String email = '',
    String phone = '',
  }) async {
    final teacherId = _db.auth.currentUser?.id;
    if (teacherId == null) return;

    final student = Student(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      batchId: batchId,
      name: name,
      rollNumber: rollNumber,
      email: email,
      phone: phone,
    );

    try {
      await _db.from('students').insert({
        ...student.toSupabase(),
        'teacher_id': teacherId,
      });
      _students.add(student);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding student: $e');
    }
  }

  Future<void> updateStudent(Student updatedStudent) async {
    try {
      await _db
          .from('students')
          .update(updatedStudent.toSupabase())
          .eq('id', updatedStudent.id);
      final index = _students.indexWhere((s) => s.id == updatedStudent.id);
      if (index != -1) {
        _students[index] = updatedStudent;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating student: $e');
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _db.from('students').delete().eq('id', id);
      _students.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting student: $e');
    }
  }

  Future<void> deleteStudentsByBatchId(String batchId) async {
    // DB cascade removes rows when batch is deleted; clear local cache
    _students.removeWhere((s) => s.batchId == batchId);
    notifyListeners();
  }

  Student? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}

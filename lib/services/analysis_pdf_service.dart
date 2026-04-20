import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analysis_pdf_record.dart';
import '../models/student_grade_model.dart';
import '../models/student_model.dart';
import 'analysis_pdf_binary_store.dart';

class AnalysisPdfService {
  static const String _historyKey = 'analysis_pdf_history';
  static const String _historyTable = 'analysis_pdf_history';
  static const String _historyBucket = 'analysis-pdfs';

  static SupabaseClient get _db => Supabase.instance.client;
  static final AnalysisPdfBinaryStore _binaryStore =
      createAnalysisPdfBinaryStore();

  static Future<AnalysisPdfRecord> exportSemesterWiseAnalysis({
    required Student student,
    required StudentGradeData gradeData,
  }) async {
    final now = DateTime.now();
    final dateTag = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'semester_analysis_${student.rollNumber}_$dateTag.pdf';
    final title = 'Semester Analysis (${student.name})';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('GradeBridge - Semester Analysis'),
          ),
          _studentInfo(student: student, generatedAt: now),
          pw.SizedBox(height: 12),
          _summaryRow(
            entries: [
              'CGPA: ${gradeData.cgpa.toStringAsFixed(2)}',
              'Semesters: ${gradeData.totalSemesters}',
              'Total Credits: ${gradeData.totalCredits}',
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Semester Breakdown',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _semesterTable(gradeData.semesters),
        ],
      ),
    );

    final bytes = await doc.save();
    return _saveAndShare(
      pdfBytes: bytes,
      title: title,
      analysisType: 'semester',
      studentId: student.id,
      studentName: student.name,
      fileName: fileName,
      shareText: 'Semester-wise analysis PDF for ${student.name}',
    );
  }

  static Future<AnalysisPdfRecord> exportSubjectWiseAnalysis({
    required Student student,
    required StudentSemester semester,
    required int semesterIndex,
  }) async {
    final now = DateTime.now();
    final dateTag = DateFormat('yyyyMMdd_HHmmss').format(now);
    final semName = semester.semesterName.isNotEmpty
        ? semester.semesterName
        : 'Semester $semesterIndex';
    final fileName =
        'subject_analysis_${student.rollNumber}_S${semesterIndex}_$dateTag.pdf';
    final title = 'Subject Analysis (${student.name} - $semName)';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('GradeBridge - Subject Analysis')),
          _studentInfo(student: student, generatedAt: now),
          pw.SizedBox(height: 12),
          _summaryRow(
            entries: [
              semName,
              'SGPA: ${semester.sgpa.toStringAsFixed(2)}',
              'Credits: ${semester.totalCredits}',
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Subject Breakdown',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _subjectTable(semester.subjects),
        ],
      ),
    );

    final bytes = await doc.save();
    return _saveAndShare(
      pdfBytes: bytes,
      title: title,
      analysisType: 'subject',
      studentId: student.id,
      studentName: student.name,
      fileName: fileName,
      shareText: 'Subject-wise analysis PDF for ${student.name}',
    );
  }

  static Future<List<AnalysisPdfRecord>> getHistory({String? studentId}) async {
    final remoteHistory = await _getRemoteHistory(studentId: studentId);
    if (remoteHistory.isNotEmpty) {
      return remoteHistory;
    }

    return _getLocalHistory(studentId: studentId);
  }

  static Future<void> shareHistoryRecord(AnalysisPdfRecord record) async {
    final bytes = await _readPdfBytes(record);
    if (bytes == null) {
      throw Exception('Saved PDF file is no longer available.');
    }

    final file = XFile.fromData(
      bytes,
      name: record.fileName,
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([file], text: record.title);
  }

  static Future<void> deleteHistoryRecord(AnalysisPdfRecord record) async {
    await _binaryStore.delete(filePath: record.pdfPath);

    final userId = _db.auth.currentUser?.id;
    if (userId != null) {
      try {
        if (record.pdfPath != null && record.pdfPath!.isNotEmpty) {
          await _db.storage.from(_historyBucket).remove([record.pdfPath!]);
        }
      } catch (e) {
        debugPrint('Failed removing PDF file from storage: $e');
      }

      try {
        await _db
            .from(_historyTable)
            .delete()
            .eq('id', record.id)
            .eq('owner_user_id', userId);
      } catch (e) {
        debugPrint('Failed deleting PDF history row from database: $e');
      }
    }

    final all = await _getLocalHistory();
    final updated = all.where((entry) => entry.id != record.id).toList();
    await _saveHistoryRecords(updated);
  }

  static Future<AnalysisPdfRecord> _saveAndShare({
    required Uint8List pdfBytes,
    required String title,
    required String analysisType,
    required String studentId,
    required String studentName,
    required String fileName,
    required String shareText,
  }) async {
    final saveResult = await _binaryStore.save(
      fileName: fileName,
      pdfBytes: pdfBytes,
    );

    final recordId = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = _db.auth.currentUser?.id;
    String? storagePath;

    if (userId != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      storagePath = '$userId/$studentId/${timestamp}_$fileName';
      try {
        await _db.storage
            .from(_historyBucket)
            .uploadBinary(
              storagePath,
              pdfBytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'application/pdf',
              ),
            );
      } catch (e) {
        debugPrint('Failed uploading PDF to storage: $e');
        storagePath = null;
      }
    }

    final record = AnalysisPdfRecord(
      id: recordId,
      title: title,
      analysisType: analysisType,
      studentId: studentId,
      studentName: studentName,
      fileName: fileName,
      pdfPath: storagePath ?? saveResult.filePath,
      pdfBase64: storagePath == null ? saveResult.inlineBase64 : null,
      createdAt: DateTime.now(),
    );

    if (userId != null && storagePath != null) {
      try {
        await _db.from(_historyTable).insert({
          'id': record.id,
          'owner_user_id': userId,
          'student_id': record.studentId,
          'student_name': record.studentName,
          'title': record.title,
          'analysis_type': record.analysisType,
          'file_name': record.fileName,
          'storage_path': storagePath,
          'created_at': record.createdAt.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Failed saving PDF history row to database: $e');
      }
    }

    final existing = await _getLocalHistory();
    final merged = [record, ...existing.where((e) => e.id != record.id)];
    await _saveHistoryRecords(merged);

    final file = XFile.fromData(
      pdfBytes,
      name: fileName,
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([file], text: shareText);

    return record;
  }

  static Future<List<AnalysisPdfRecord>> _getRemoteHistory({
    String? studentId,
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      return const <AnalysisPdfRecord>[];
    }

    try {
      final baseQuery = _db
          .from(_historyTable)
          .select()
          .eq('owner_user_id', userId);

      final rows = studentId == null
          ? await baseQuery.order('created_at', ascending: false)
          : await baseQuery
                .eq('student_id', studentId)
                .order('created_at', ascending: false);

      return (rows as List).map((row) => Map<String, dynamic>.from(row)).map((
        row,
      ) {
        final createdValue = row['created_at'];
        final createdAt = createdValue is String
            ? DateTime.parse(createdValue)
            : DateTime.tryParse('${createdValue ?? ''}') ?? DateTime.now();

        return AnalysisPdfRecord(
          id: row['id'] as String,
          title: row['title'] as String,
          analysisType: row['analysis_type'] as String,
          studentId: row['student_id'] as String,
          studentName: row['student_name'] as String,
          fileName: row['file_name'] as String,
          pdfPath: row['storage_path'] as String?,
          pdfBase64: null,
          createdAt: createdAt,
        );
      }).toList();
    } catch (e) {
      debugPrint('Failed loading PDF history from database: $e');
      return const <AnalysisPdfRecord>[];
    }
  }

  static Future<List<AnalysisPdfRecord>> _getLocalHistory({
    String? studentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = json.decode(raw) as List<dynamic>;
    final storedRecords = decoded
        .map((e) => AnalysisPdfRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final all = <AnalysisPdfRecord>[];
    var didChange = false;

    for (final record in storedRecords) {
      if (_isRemoteStoragePath(record.pdfPath)) {
        all.add(record);
        continue;
      }

      final normalizedRecord = await _normalizeRecord(record);
      final exists = await _binaryStore.exists(
        filePath: normalizedRecord.pdfPath,
        inlineBase64: normalizedRecord.pdfBase64,
      );

      if (!exists) {
        didChange = true;
        continue;
      }

      if (normalizedRecord.pdfPath != record.pdfPath ||
          normalizedRecord.pdfBase64 != record.pdfBase64) {
        didChange = true;
      }

      all.add(normalizedRecord);
    }

    if (didChange) {
      await _saveHistoryRecords(all);
    }

    final filtered = studentId == null
        ? all
        : all.where((e) => e.studentId == studentId).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  static Future<Uint8List?> _readPdfBytes(AnalysisPdfRecord record) async {
    final localBytes = await _binaryStore.load(
      filePath: record.pdfPath,
      inlineBase64: record.pdfBase64,
    );
    if (localBytes != null) {
      return localBytes;
    }

    final storagePath = record.pdfPath;
    if (storagePath == null || storagePath.isEmpty) {
      return null;
    }

    try {
      return await _db.storage.from(_historyBucket).download(storagePath);
    } catch (e) {
      debugPrint('Failed downloading PDF from storage: $e');
      return null;
    }
  }

  static bool _isRemoteStoragePath(String? path) {
    if (path == null || path.isEmpty) {
      return false;
    }

    final startsLikeLocalWindows = path.contains(':\\') || path.contains(':/');
    final startsLikeLocalUnix = path.startsWith('/');
    return !startsLikeLocalWindows && !startsLikeLocalUnix;
  }

  static Future<AnalysisPdfRecord> _normalizeRecord(
    AnalysisPdfRecord record,
  ) async {
    if (record.pdfPath != null && record.pdfPath!.isNotEmpty) {
      return record;
    }

    if (record.pdfBase64 == null || record.pdfBase64!.isEmpty) {
      return record;
    }

    final migrated = await _binaryStore.save(
      fileName: record.fileName,
      pdfBytes: base64Decode(record.pdfBase64!),
    );

    return record.copyWith(
      pdfPath: migrated.filePath,
      pdfBase64: migrated.inlineBase64,
    );
  }

  static Future<void> _saveHistoryRecords(
    List<AnalysisPdfRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      json.encode(records.map((e) => e.toJson()).toList()),
    );
  }

  static pw.Widget _studentInfo({
    required Student student,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Student: ${student.name}'),
          pw.Text('Roll No: ${student.rollNumber}'),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(generatedAt)}',
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow({required List<String> entries}) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 6,
      children: entries
          .map(
            (e) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(e),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _semesterTable(List<StudentSemester> semesters) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _header(['Semester', 'SGPA', 'Subjects', 'Credits']),
        ...semesters.asMap().entries.map((entry) {
          final idx = entry.key;
          final sem = entry.value;
          final semName = sem.semesterName.isNotEmpty
              ? sem.semesterName
              : 'Semester ${idx + 1}';
          return _row([
            semName,
            sem.sgpa.toStringAsFixed(2),
            '${sem.subjects.length}',
            '${sem.totalCredits}',
          ]);
        }),
      ],
    );
  }

  static pw.Widget _subjectTable(List<StudentSubject> subjects) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _header(['Subject', 'Grade', 'Grade Points', 'Credits']),
        ...subjects.map(
          (sub) => _row([
            sub.name,
            sub.grade,
            sub.gradePoints.toStringAsFixed(1),
            '${sub.credits}',
          ]),
        ),
      ],
    );
  }

  static pw.TableRow _header(List<String> cols) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue100),
      children: cols
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                c,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.TableRow _row(List<String> cols) {
    return pw.TableRow(
      children: cols
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(c),
            ),
          )
          .toList(),
    );
  }
}

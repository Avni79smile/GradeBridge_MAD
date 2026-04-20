import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/student_grade_model.dart';
import '../models/student_model.dart';
import '../providers/student_grade_provider.dart';
import '../providers/theme_provider.dart';
import 'semester_detail_page.dart';

class SemesterHistoryPage extends StatelessWidget {
  final Student student;

  const SemesterHistoryPage({super.key, required this.student});

  List<_SemesterHistoryEntry> _buildEntries(List<StudentSemester> semesters) {
    final orderedSemesters = semesters.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double totalPoints = 0;
    double totalCredits = 0;
    final entries = <_SemesterHistoryEntry>[];

    for (final semester in orderedSemesters) {
      final semesterPoints = semester.subjects.fold<double>(
        0,
        (sum, subject) => sum + (subject.gradePoints * subject.credits),
      );
      final semesterCredits = semester.totalCredits.toDouble();

      totalPoints += semesterPoints;
      totalCredits += semesterCredits;

      entries.add(
        _SemesterHistoryEntry(
          semester: semester,
          cumulativeCgpa: totalCredits > 0 ? totalPoints / totalCredits : 0.0,
        ),
      );
    }

    return entries.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'History',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<StudentGradeProvider>(
        builder: (context, provider, _) {
          final gradeData = provider.getOrCreateGradeData(student.id);
          final entries = _buildEntries(gradeData.semesters);

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 72,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No semester history yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saved semesters will appear here as cards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SemesterDetailPage(
                      student: student,
                      semester: entry.semester,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: entry.semester.toolUsed == 'cgpa'
                          ? const [Color(0xFF6C63FF), Color(0xFF4FACFE)]
                          : const [Color(0xFF00C9A7), Color(0xFF00B4DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (entry.semester.toolUsed == 'cgpa'
                                    ? const Color(0xFF6C63FF)
                                    : const Color(0xFF00C9A7))
                                .withAlpha(70),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(35),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'S${entries.length - index}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.semester.semesterName.isNotEmpty
                                      ? entry.semester.semesterName
                                      : 'Semester ${entries.length - index}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(entry.semester.createdAt)} • ${entry.semester.subjects.length} subjects',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(220),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.white.withAlpha(210),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetricChip(
                            label: 'SGPA',
                            value: entry.semester.sgpa.toStringAsFixed(2),
                          ),
                          _MetricChip(
                            label: 'CGPA',
                            value: entry.cumulativeCgpa.toStringAsFixed(2),
                          ),
                          _MetricChip(
                            label: 'Percentage',
                            value: (entry.cumulativeCgpa * 9.5)
                                .clamp(0, 100)
                                .toStringAsFixed(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(28),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              entry.semester.toolUsed == 'cgpa'
                                  ? 'Calculated with CGPA'
                                  : 'Calculated with SGPA',
                              style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${entry.semester.totalCredits} credits',
                            style: TextStyle(
                              color: Colors.white.withAlpha(220),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SemesterHistoryEntry {
  final StudentSemester semester;
  final double cumulativeCgpa;

  _SemesterHistoryEntry({required this.semester, required this.cumulativeCgpa});
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

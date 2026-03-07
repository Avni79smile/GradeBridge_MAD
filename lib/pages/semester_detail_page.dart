import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../models/student_grade_model.dart';
import '../providers/theme_provider.dart';
import '../providers/student_grade_provider.dart';
import 'student_sgpa_page.dart';
import 'student_cgpa_page.dart';

class SemesterDetailPage extends StatelessWidget {
  final Student student;
  final StudentSemester semester;

  const SemesterDetailPage({
    super.key,
    required this.student,
    required this.semester,
  });

  void _showAddSubjectsToolPicker(
    BuildContext context,
    StudentSemester currentSem,
  ) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    // Pre-select based on stored toolUsed so new semesters confirm in one tap.
    String selected = currentSem.toolUsed;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add Subjects to ${currentSem.semesterName.isNotEmpty ? currentSem.semesterName : "Semester"}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Which calculator did you use for this semester?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _toolTile(
                    ctx,
                    isDark: isDark,
                    label: 'SGPA',
                    subtitle: 'Semester GPA\ncalculator',
                    icon: Icons.school_rounded,
                    color: const Color(0xFF00C9A7),
                    selected: selected == 'sgpa',
                    onTap: () => setSheet(() => selected = 'sgpa'),
                  ),
                  const SizedBox(width: 12),
                  _toolTile(
                    ctx,
                    isDark: isDark,
                    label: 'CGPA',
                    subtitle: 'Cumulative GPA\ncalculator',
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFF6C63FF),
                    selected: selected == 'cgpa',
                    onTap: () => setSheet(() => selected = 'cgpa'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (selected == 'cgpa') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentCgpaPage(
                            student: student,
                            initialSemesterName: currentSem.semesterName,
                            existingSemesterId: currentSem.id,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentSgpaPage(
                            student: student,
                            initialSemesterName: currentSem.semesterName,
                            existingSemesterId: currentSem.id,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected == 'cgpa'
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF00C9A7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolTile(
    BuildContext context, {
    required bool isDark,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color
                  : (isDark ? Colors.white24 : Colors.black12),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? color
                    : (isDark ? Colors.white38 : Colors.black38),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: selected
                      ? color
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'O':
        return const Color(0xFF10B981);
      case 'A+':
        return const Color(0xFF059669);
      case 'A':
        return const Color(0xFF3B82F6);
      case 'B+':
      case 'B':
        return const Color(0xFF6366F1);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'P':
        return const Color(0xFF78716C);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

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
          semester.semesterName.isNotEmpty ? semester.semesterName : 'Semester',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<StudentGradeProvider>(
        builder: (context, provider, _) {
          final gradeData = provider.getGradeData(student.id);
          final currentSem =
              gradeData?.semesters.firstWhere(
                (s) => s.id == semester.id,
                orElse: () => semester,
              ) ??
              semester;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSgpaCard(currentSem),
                const SizedBox(height: 24),

                // Subjects header
                Row(
                  children: [
                    Text(
                      'Subjects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentSem.subjects.length} subjects',
                        style: const TextStyle(
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (currentSem.subjects.isEmpty)
                  _buildEmpty(isDark)
                else
                  ...currentSem.subjects.map(
                    (s) => _buildSubjectCard(
                      isDark,
                      s,
                      context,
                      provider,
                      currentSem,
                    ),
                  ),

                const SizedBox(height: 24),

                // Add More Subjects button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C9A7), Color(0xFF00B4DB)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C9A7).withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showAddSubjectsToolPicker(context, currentSem),
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text(
                        'ADD MORE SUBJECTS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSgpaCard(StudentSemester sem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sem.semesterName.isNotEmpty ? sem.semesterName : 'Semester',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  sem.sgpa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SGPA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sem.totalCredits} Cr',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sem.subjects.length} subs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    bool isDark,
    StudentSubject subject,
    BuildContext context,
    StudentGradeProvider provider,
    StudentSemester currentSem,
  ) {
    final gc = _gradeColor(subject.grade);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: gc.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  subject.grade,
                  style: TextStyle(
                    color: gc,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip('${subject.credits} Credits', isDark),
                      const SizedBox(width: 8),
                      _chip(
                        'GP: ${subject.gradePoints.toStringAsFixed(1)}',
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              onPressed: () {
                final updatedSubjects = currentSem.subjects
                    .where((s) => s.id != subject.id)
                    .toList();
                final sgpa = provider.calculateSGPA(updatedSubjects);
                provider.updateSemester(
                  student.id,
                  StudentSemester(
                    id: currentSem.id,
                    semesterName: currentSem.semesterName,
                    subjects: updatedSubjects,
                    sgpa: sgpa,
                    createdAt: currentSem.createdAt,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.book_outlined,
            size: 48,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            'No subjects yet',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }
}

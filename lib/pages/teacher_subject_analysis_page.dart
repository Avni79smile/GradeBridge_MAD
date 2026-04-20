import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_model.dart';
import '../models/student_grade_model.dart';
import '../providers/theme_provider.dart';
import '../providers/student_grade_provider.dart';
import '../services/analysis_pdf_service.dart';

/// Subject-wise analysis for a specific semester (teacher view).
/// Shows grade distribution, subject grade-point bars, credits breakdown
/// and a detailed subject list for the given [semester].
class TeacherSubjectAnalysisPage extends StatelessWidget {
  final Student student;
  final StudentSemester semester;
  final int semesterIndex; // 1-based display number
  final VoidCallback? onSwitchToSemesterWise;

  const TeacherSubjectAnalysisPage({
    super.key,
    required this.student,
    required this.semester,
    required this.semesterIndex,
    this.onSwitchToSemesterWise,
  });

  // ─────────────────────── helpers ────────────────────────

  static const Map<String, Color> _gradeColors = {
    'O': Color(0xFF10B981),
    'A+': Color(0xFF059669),
    'A': Color(0xFF3B82F6),
    'B+': Color(0xFF6366F1),
    'B': Color(0xFFF59E0B),
    'C+': Color(0xFFF97316),
    'C': Color(0xFFEF4444),
    'D': Color(0xFF78716C),
    'P': Color(0xFF78716C),
    'F': Color(0xFFDC2626),
  };

  Color _gradeColor(String grade) =>
      _gradeColors[grade] ?? const Color(0xFF94A3B8);

  Color _sgpaColor(double sgpa) {
    if (sgpa >= 9) return const Color(0xFF10B981);
    if (sgpa >= 8) return const Color(0xFF059669);
    if (sgpa >= 7) return const Color(0xFF3B82F6);
    if (sgpa >= 6) return const Color(0xFFF59E0B);
    if (sgpa >= 5) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  BoxDecoration _card(bool isDark) => BoxDecoration(
    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _sectionTitle(String title, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    ),
  );

  // ─────────────────────── build ──────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final subjects = semester.subjects;
    final semName = semester.semesterName.isNotEmpty
        ? semester.semesterName
        : 'Semester $semesterIndex';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leadingWidth: 92,
        leading: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            IconButton(
              tooltip: 'Export PDF',
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              color: const Color(0xFFEF4444),
              onPressed: () => _exportSubjectAnalysis(context),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Switch analysis view',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _showSwitchSheet(context, isDark),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Switch', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Analysis',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              semName,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: subjects.isEmpty
          ? _buildEmptyState(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(isDark, semName),
                  const SizedBox(height: 24),

                  _sectionTitle('Grade Points per Subject', isDark),
                  _buildGradePointsBars(isDark),
                  const SizedBox(height: 24),

                  _sectionTitle('Grade Distribution', isDark),
                  _buildGradeDistribution(isDark),
                  const SizedBox(height: 24),

                  _sectionTitle('Credits Breakdown', isDark),
                  _buildCreditsBreakdown(isDark),
                  const SizedBox(height: 24),

                  _sectionTitle('Subject Details', isDark),
                  _buildSubjectList(isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─────────────────────── header card ────────────────────

  Widget _buildHeaderCard(bool isDark, String semName) {
    final color = _sgpaColor(semester.sgpa);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // student avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  semName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${semester.subjects.length} subjects  •  ${semester.totalCredits} credits',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // SGPA badge
          Column(
            children: [
              Text(
                semester.sgpa.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'SGPA',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────── switch sheet ──────────────────────────

  void _showSwitchSheet(BuildContext context, bool isDark) {
    final provider = Provider.of<StudentGradeProvider>(context, listen: false);
    final allSemesters = provider.getGradeData(student.id)?.semesters ?? [];
    final nav = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Switch Analysis View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose another view or semester',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 20),
            if (onSwitchToSemesterWise != null) ...[
              _switchOption(
                isDark: isDark,
                icon: Icons.stacked_bar_chart_rounded,
                color: const Color(0xFF6366F1),
                title: 'Overall Semester Analysis',
                subtitle: 'SGPA trend & all semesters summary',
                isCurrent: false,
                onTap: () {
                  Navigator.pop(ctx);
                  onSwitchToSemesterWise!();
                },
              ),
              const SizedBox(height: 12),
            ],
            if (allSemesters.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Subject-wise – Pick Semester',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...allSemesters.asMap().entries.map((entry) {
                final idx = entry.key;
                final sem = entry.value;
                final isCurrent = sem.id == semester.id;
                final semName = sem.semesterName.isNotEmpty
                    ? sem.semesterName
                    : 'Semester ${idx + 1}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _switchOption(
                    isDark: isDark,
                    icon: Icons.subject_rounded,
                    color: isCurrent
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFFFF6B6B),
                    title: semName,
                    subtitle: isCurrent
                        ? '${sem.subjects.length} subjects  \u2022  ${sem.totalCredits} credits  (current)'
                        : '${sem.subjects.length} subjects  \u2022  ${sem.totalCredits} credits',
                    isCurrent: isCurrent,
                    onTap: isCurrent
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            nav.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => TeacherSubjectAnalysisPage(
                                  student: student,
                                  semester: sem,
                                  semesterIndex: idx + 1,
                                  onSwitchToSemesterWise:
                                      onSwitchToSemesterWise,
                                ),
                              ),
                            );
                          },
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _switchOption({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isCurrent,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: isCurrent ? 0.45 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrent)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────── grade points horizontal bars ───────────

  Widget _buildGradePointsBars(bool isDark) {
    final subjects = semester.subjects;
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(isDark),
      child: Column(
        children: subjects.map((sub) {
          final color = _gradeColor(sub.grade);
          final pct = sub.gradePoints / 10.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    sub.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 12,
                      backgroundColor: isDark
                          ? Colors.white10
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    sub.gradePoints.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    sub.grade,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────── grade distribution pie + legend ────────

  Widget _buildGradeDistribution(bool isDark) {
    final gradeCount = <String, int>{};
    for (final sub in semester.subjects) {
      gradeCount[sub.grade] = (gradeCount[sub.grade] ?? 0) + 1;
    }
    if (gradeCount.isEmpty) return const SizedBox.shrink();

    final sections = gradeCount.entries.map((e) {
      final color = _gradeColor(e.key);
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: e.key,
        color: color,
        radius: 58,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(isDark),
      child: Row(
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 38,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gradeCount.entries.map((e) {
                final color = _gradeColor(e.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grade ${e.key}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${e.value}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────── credits breakdown bar chart ────────────

  Widget _buildCreditsBreakdown(bool isDark) {
    final subjects = semester.subjects;
    if (subjects.isEmpty) return const SizedBox.shrink();

    final maxCredits = subjects
        .map((s) => s.credits)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(isDark),
      child: Column(
        children: subjects.map((sub) {
          final color = _gradeColor(sub.grade);
          final pct = maxCredits > 0 ? sub.credits / maxCredits : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    sub.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 12,
                      backgroundColor: isDark
                          ? Colors.white10
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        color.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${sub.credits} cr',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────── subject detail cards ───────────────────

  Widget _buildSubjectList(bool isDark) {
    final subjects = semester.subjects;
    final totalWeighted = subjects.fold<double>(
      0,
      (sum, s) => sum + s.gradePoints * s.credits,
    );
    final totalCredits = semester.totalCredits;

    return Column(
      children: subjects.asMap().entries.map((entry) {
        final idx = entry.key;
        final sub = entry.value;
        final color = _gradeColor(sub.grade);
        final contribution = totalCredits > 0
            ? (sub.gradePoints * sub.credits) / totalWeighted * 100
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: _card(isDark),
          child: Row(
            children: [
              // index badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _chip('${sub.credits} cr', isDark),
                        const SizedBox(width: 6),
                        _chip(
                          '${sub.gradePoints.toStringAsFixed(1)} pts',
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _chip(
                          '${contribution.toStringAsFixed(1)}% contrib',
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // grade badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  sub.grade,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _chip(String label, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: isDark ? Colors.white60 : Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // ──────────────── empty state ─────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Subjects Added',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subjects to this semester to see analysis',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _exportSubjectAnalysis(BuildContext context) async {
    try {
      if (semester.subjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subject data to export yet.')),
        );
        return;
      }

      await AnalysisPdfService.exportSubjectWiseAnalysis(
        student: student,
        semester: semester,
        semesterIndex: semesterIndex,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject analysis PDF generated and saved.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }
}

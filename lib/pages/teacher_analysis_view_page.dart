import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_grade_model.dart';
import '../providers/theme_provider.dart';

/// Shown to a STUDENT to view the analytics / grades their teacher has entered
/// for them.  Reads from [StudentGradeProvider.myTeacherGradeData].
class TeacherAnalysisViewPage extends StatelessWidget {
  final StudentGradeData gradeData;

  const TeacherAnalysisViewPage({super.key, required this.gradeData});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;

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
          "Teacher's Analysis",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: gradeData.semesters.isEmpty
          ? _buildEmptyState(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  _buildHeaderCard(isDark),
                  const SizedBox(height: 24),

                  // SGPA Trend
                  _buildSectionTitle('SGPA Trend by Semester', isDark),
                  const SizedBox(height: 12),
                  _buildSgpaTrendChart(isDark),
                  const SizedBox(height: 24),

                  // Grade distribution
                  _buildSectionTitle('Grade Distribution', isDark),
                  const SizedBox(height: 12),
                  _buildGradeDistribution(isDark),
                  const SizedBox(height: 24),

                  // Semester-wise breakdown
                  _buildSectionTitle('Semester Breakdown', isDark),
                  const SizedBox(height: 12),
                  _buildSemesterList(isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHeaderCard(bool isDark) {
    final cgpa = gradeData.cgpa;
    final grade = _cgpaToGrade(cgpa);
    final color = _cgpaColor(cgpa);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Academic Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gradeData.semesters.length} Semester(s) â€¢ ${gradeData.totalCredits} Credits',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${_formatDate(gradeData.lastUpdated)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                cgpa.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                grade,
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ SGPA Trend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSgpaTrendChart(bool isDark) {
    final semesters = gradeData.semesters;
    final spots = <FlSpot>[];
    for (int i = 0; i < semesters.length; i++) {
      spots.add(FlSpot(i.toDouble(), semesters[i].sgpa));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: semesters.length < 2
          ? Center(
              child: Text(
                'Need at least 2 semesters for trend',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[500],
                ),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= 0 && idx < semesters.length) {
                          return Text(
                            'S${idx + 1}',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey[600],
                              fontSize: 11,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (semesters.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF6C63FF),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFF6C63FF),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6C63FF).withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Grade distribution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildGradeDistribution(bool isDark) {
    final gradeCount = <String, int>{};
    for (final sem in gradeData.semesters) {
      for (final sub in sem.subjects) {
        gradeCount[sub.grade] = (gradeCount[sub.grade] ?? 0) + 1;
      }
    }

    if (gradeCount.isEmpty) {
      return Container(
        height: 120,
        decoration: _cardDecoration(isDark),
        child: Center(
          child: Text(
            'No subjects data',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500]),
          ),
        ),
      );
    }

    const gradeColors = {
      'O': Color(0xFF10B981),
      'A+': Color(0xFF059669),
      'A': Color(0xFF3B82F6),
      'B+': Color(0xFF6366F1),
      'B': Color(0xFFF59E0B),
      'C': Color(0xFFEF4444),
      'P': Color(0xFF78716C),
      'F': Color(0xFFDC2626),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: gradeCount.entries.map((entry) {
          final color = gradeColors[entry.key] ?? const Color(0xFF94A3B8);
          final total = gradeCount.values.fold(0, (sum, v) => sum + v);
          final pct = total > 0 ? entry.value / total : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: isDark
                          ? Colors.white10
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Semester list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSemesterList(bool isDark) {
    return Column(
      children: List.generate(gradeData.semesters.length, (index) {
        final sem = gradeData.semesters[index];
        final color = _sgpaColor(sem.sgpa);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _cardDecoration(isDark),
          child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'S${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              title: Text(
                sem.semesterName.isNotEmpty
                    ? sem.semesterName
                    : 'Semester ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                '${sem.subjects.length} subject(s) â€¢ ${sem.totalCredits} credits',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sem.sgpa.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'SGPA',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              children: [
                if (sem.subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'No subjects added yet.',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  )
                else
                  ...sem.subjects.map((sub) => _buildSubjectRow(sub, isDark)),
                const SizedBox(height: 8),
              ],
            ),
        );
      }),
    );
  }

  Widget _buildSubjectRow(StudentSubject sub, bool isDark) {
    const gradeColors = {
      'O': Color(0xFF10B981),
      'A+': Color(0xFF059669),
      'A': Color(0xFF3B82F6),
      'B+': Color(0xFF6366F1),
      'B': Color(0xFFF59E0B),
      'C': Color(0xFFEF4444),
      'P': Color(0xFF78716C),
      'F': Color(0xFFDC2626),
    };
    final gc = gradeColors[sub.grade] ?? const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              sub.name,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${sub.credits} cr',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 26,
            decoration: BoxDecoration(
              color: gc.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              sub.grade,
              style: TextStyle(
                color: gc,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            'No Teacher Reports Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your teacher hasn\'t added any grades for you yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.25)
            : Colors.grey.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Color _sgpaColor(double sgpa) {
    if (sgpa >= 9) return const Color(0xFF10B981);
    if (sgpa >= 8) return const Color(0xFF3B82F6);
    if (sgpa >= 7) return const Color(0xFF6366F1);
    if (sgpa >= 6) return const Color(0xFFF59E0B);
    if (sgpa >= 5) return const Color(0xFFEF4444);
    return const Color(0xFFDC2626);
  }

  Color _cgpaColor(double cgpa) {
    if (cgpa >= 9) return const Color(0xFF10B981);
    if (cgpa >= 8) return const Color(0xFF3B82F6);
    if (cgpa >= 7) return const Color(0xFF6C63FF);
    if (cgpa >= 6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _cgpaToGrade(double cgpa) {
    if (cgpa >= 9.0) return 'Outstanding';
    if (cgpa >= 8.0) return 'Excellent';
    if (cgpa >= 7.0) return 'Very Good';
    if (cgpa >= 6.0) return 'Good';
    if (cgpa >= 5.0) return 'Average';
    if (cgpa >= 4.0) return 'Pass';
    return 'Needs Improvement';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

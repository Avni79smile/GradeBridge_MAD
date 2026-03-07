import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_model.dart';
import '../providers/theme_provider.dart';
import '../providers/student_grade_provider.dart';

class StudentAnalyticsPage extends StatelessWidget {
  final Student student;

  const StudentAnalyticsPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
          'Analytics',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<StudentGradeProvider>(
        builder: (context, provider, _) {
          final gradeData = provider.getOrCreateGradeData(student.id);

          if (gradeData.semesters.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Info Header
                _buildStudentHeader(isDark, gradeData.cgpa),
                const SizedBox(height: 24),

                // SGPA Trend Chart
                _buildSectionTitle('SGPA Trend', isDark),
                const SizedBox(height: 12),
                _buildSgpaTrendChart(isDark, gradeData.semesters),
                const SizedBox(height: 24),

                // Grade Distribution
                _buildSectionTitle('Overall Grade Distribution', isDark),
                const SizedBox(height: 12),
                _buildGradeDistributionChart(isDark, gradeData.semesters),
                const SizedBox(height: 24),

                // Semester-wise Stats
                _buildSectionTitle('Semester Statistics', isDark),
                const SizedBox(height: 12),
                _buildSemesterStats(isDark, gradeData.semesters),
              ],
            ),
          );
        },
      ),
    );
  }

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
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add semesters to see analytics',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(bool isDark, double cgpa) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  student.rollNumber,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'CGPA',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSgpaTrendChart(bool isDark, List semesters) {
    final spots = <FlSpot>[];
    for (int i = 0; i < semesters.length; i++) {
      spots.add(FlSpot(i.toDouble(), semesters[i].sgpa));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white12 : Colors.grey[200]!,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < semesters.length) {
                    return Text(
                      'S${value.toInt() + 1}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontSize: 12,
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
              color: const Color(0xFFFF6B6B),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: const Color(0xFFFF6B6B),
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistributionChart(bool isDark, List semesters) {
    final gradeCount = <String, int>{};

    for (var semester in semesters) {
      for (var subject in semester.subjects) {
        gradeCount[subject.grade] = (gradeCount[subject.grade] ?? 0) + 1;
      }
    }

    if (gradeCount.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No subjects data',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
          ),
        ),
      );
    }

    final gradeColors = {
      'O': Colors.green,
      'A+': Colors.teal,
      'A': Colors.blue,
      'B+': Colors.indigo,
      'B': Colors.orange,
      'C': Colors.deepOrange,
      'P': Colors.brown,
      'F': Colors.red,
    };

    final sections = gradeCount.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        color: gradeColors[entry.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildSemesterStats(bool isDark, List semesters) {
    return Column(
      children: List.generate(semesters.length, (index) {
        final semester = semesters[index];
        final totalCredits = semester.subjects.fold<int>(
          0,
          (sum, subject) => sum + subject.credits as int,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSgpaColor(semester.sgpa).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'S${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSgpaColor(semester.sgpa),
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
                      'Semester ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${semester.subjects.length} Subjects | $totalCredits Credits',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    semester.sgpa.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getSgpaColor(semester.sgpa),
                    ),
                  ),
                  Text(
                    'SGPA',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Color _getSgpaColor(double sgpa) {
    if (sgpa >= 9) return Colors.green;
    if (sgpa >= 8) return Colors.teal;
    if (sgpa >= 7) return Colors.blue;
    if (sgpa >= 6) return Colors.orange;
    if (sgpa >= 5) return Colors.deepOrange;
    return Colors.red;
  }
}

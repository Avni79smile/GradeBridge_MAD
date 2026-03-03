import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/calculation_history_provider.dart';
import '../models/calculation_model.dart';
import '../services/pdf_export_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  late TabController _tabController;
  final TextEditingController _targetGpaController = TextEditingController();
  double? _requiredGpa;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalculationHistoryProvider>().loadCalculations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetGpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Consumer<CalculationHistoryProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (provider.calculations.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  _buildHeader(provider),
                  _buildTabBar(),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(provider),
                          _buildTrendsTab(provider),
                          _buildGoalsTab(provider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Analytics Yet',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start calculating CGPA/SGPA\nto see your analytics here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(200)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CalculationHistoryProvider provider) {
    final calculations = provider.calculations;
    final average =
        calculations.fold(0.0, (prev, curr) => prev + curr.result) /
        calculations.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.white,
                ),
                onPressed: () => _exportPdf(provider),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderStat(
                  'Overall GPA',
                  average.toStringAsFixed(2),
                  Icons.star,
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withAlpha(50),
                ),
                _buildHeaderStat(
                  'Total',
                  '${calculations.length}',
                  Icons.calculate_outlined,
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withAlpha(50),
                ),
                _buildHeaderStat(
                  'Grade',
                  _getGrade(average),
                  Icons.grade_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180)),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Trends'),
          Tab(text: 'Goals'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(CalculationHistoryProvider provider) {
    final data = _getFilteredData(provider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFilterChips(),
        const SizedBox(height: 20),
        _buildStatisticsGrid(data),
        const SizedBox(height: 20),
        _buildInsightsCard(provider),
        const SizedBox(height: 20),
        _buildRecentCalculations(data),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'CGPA', 'SGPA'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF667eea),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF667eea),
                fontWeight: FontWeight.w600,
              ),
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 0,
              shadowColor: const Color(0xFF667eea).withAlpha(100),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsGrid(List<CalculationRecord> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data for selected filter'));
    }

    final average =
        data.fold(0.0, (prev, curr) => prev + curr.result) / data.length;
    final highest = data.fold(
      0.0,
      (prev, curr) => curr.result > prev ? curr.result : prev,
    );
    final lowest = data.fold(
      double.infinity,
      (prev, curr) => curr.result < prev ? curr.result : prev,
    );
    final cgpaCount = data.where((c) => c.calculationType == 'CGPA').length;
    final sgpaCount = data.where((c) => c.calculationType == 'SGPA').length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Average',
                value: average.toStringAsFixed(2),
                icon: Icons.trending_up,
                gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Highest',
                value: highest.toStringAsFixed(2),
                icon: Icons.emoji_events,
                gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Lowest',
                value: lowest == double.infinity
                    ? '0.00'
                    : lowest.toStringAsFixed(2),
                icon: Icons.trending_down,
                gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'CGPA/SGPA',
                value: '$cgpaCount / $sgpaCount',
                icon: Icons.pie_chart,
                gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsCard(CalculationHistoryProvider provider) {
    final insights = _generateInsights(provider.calculations);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Performance Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    insight['icon'] as IconData,
                    color: insight['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight['text'] as String,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights(
    List<CalculationRecord> calculations,
  ) {
    final insights = <Map<String, dynamic>>[];

    if (calculations.isEmpty) return insights;

    final average =
        calculations.fold(0.0, (prev, curr) => prev + curr.result) /
        calculations.length;
    final highest = calculations.fold(
      0.0,
      (prev, curr) => curr.result > prev ? curr.result : prev,
    );
    final lowest = calculations.fold(
      double.infinity,
      (prev, curr) => curr.result < prev ? curr.result : prev,
    );

    // Average insight
    if (average >= 8.5) {
      insights.add({
        'icon': Icons.celebration,
        'color': Colors.green,
        'text':
            'Excellent! Your average GPA of ${average.toStringAsFixed(2)} puts you in the top tier!',
      });
    } else if (average >= 7.0) {
      insights.add({
        'icon': Icons.thumb_up,
        'color': Colors.blue,
        'text':
            'Good job! Your average GPA is ${average.toStringAsFixed(2)}. Keep pushing to reach 8.5+',
      });
    } else {
      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.orange,
        'text':
            'Your average GPA is ${average.toStringAsFixed(2)}. Focus on weak subjects to improve.',
      });
    }

    // Consistency insight
    final variance = highest - lowest;
    if (variance < 0.5 && calculations.length > 1) {
      insights.add({
        'icon': Icons.balance,
        'color': Colors.green,
        'text':
            'Great consistency! Your GPA variance is only ${variance.toStringAsFixed(2)}.',
      });
    } else if (variance > 1.5 && calculations.length > 1) {
      insights.add({
        'icon': Icons.warning_amber,
        'color': Colors.orange,
        'text':
            'High variance (${variance.toStringAsFixed(2)}) in your scores. Try to maintain consistency.',
      });
    }

    // Recent trend
    if (calculations.length >= 2) {
      final sorted = List<CalculationRecord>.from(calculations)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final recent = sorted[0].result;
      final previous = sorted[1].result;
      final diff = recent - previous;

      if (diff > 0) {
        insights.add({
          'icon': Icons.arrow_upward,
          'color': Colors.green,
          'text':
              'Your GPA improved by ${diff.toStringAsFixed(2)} in your last calculation!',
        });
      } else if (diff < 0) {
        insights.add({
          'icon': Icons.arrow_downward,
          'color': Colors.red,
          'text':
              'Your GPA dropped by ${diff.abs().toStringAsFixed(2)}. Review recent subjects.',
        });
      }
    }

    // Target suggestion
    if (average < 9.0) {
      final needed =
          (9.0 * (calculations.length + 1)) -
          calculations.fold(0.0, (prev, curr) => prev + curr.result);
      if (needed <= 10.0) {
        insights.add({
          'icon': Icons.flag,
          'color': Colors.purple,
          'text':
              'To reach 9.0 average, you need ${needed.toStringAsFixed(2)} in your next calculation.',
        });
      }
    }

    return insights;
  }

  Widget _buildRecentCalculations(List<CalculationRecord> data) {
    if (data.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Calculations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...data.take(5).map((record) => _buildCalculationTile(record)),
        ],
      ),
    );
  }

  Widget _buildCalculationTile(CalculationRecord record) {
    final isCgpa = record.calculationType == 'CGPA';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCgpa ? Colors.blue : Colors.purple).withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCgpa
                    ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
                    : [const Color(0xFFf093fb), const Color(0xFFf5576c)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCgpa ? Icons.calculate : Icons.school,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.calculationType}: ${record.result.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  record.semesterName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getGrade(record.result),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getGradeColor(record.result),
                ),
              ),
              Text(
                '${record.timestamp.day}/${record.timestamp.month}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(CalculationHistoryProvider provider) {
    final data = _getFilteredData(provider);

    if (data.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Need at least 2 calculations\nto show trends',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFilterChips(),
        const SizedBox(height: 20),
        _buildTrendChart(data),
        const SizedBox(height: 20),
        _buildSemesterComparison(data),
      ],
    );
  }

  Widget _buildTrendChart(List<CalculationRecord> data) {
    final sortedData = List<CalculationRecord>.from(data)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = sortedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.result);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GPA Trend Over Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withAlpha(50),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < sortedData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '#${value.toInt() + 1}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF667eea),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea).withAlpha(50),
                          const Color(0xFF764ba2).withAlpha(10),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterComparison(List<CalculationRecord> data) {
    final sortedData = List<CalculationRecord>.from(data)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Semester Comparison',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...sortedData.take(6).map((record) {
            final percentage = (record.result / 10) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          record.semesterName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        record.result.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getGradeColor(record.result),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getGradeColor(record.result),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(CalculationHistoryProvider provider) {
    final calculations = provider.calculations;
    final currentAverage = calculations.isEmpty
        ? 0.0
        : calculations.fold(0.0, (prev, curr) => prev + curr.result) /
              calculations.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGoalCalculator(calculations, currentAverage),
        const SizedBox(height: 20),
        _buildQuickTargets(calculations, currentAverage),
        const SizedBox(height: 20),
        _buildAchievements(calculations),
      ],
    );
  }

  Widget _buildGoalCalculator(
    List<CalculationRecord> calculations,
    double currentAverage,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Goal Calculator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Current Average: ${currentAverage.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetGpaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter Target GPA',
              hintText: 'e.g., 8.5',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.gps_fixed),
            ),
            onChanged: (value) {
              final target = double.tryParse(value);
              if (target != null && calculations.isNotEmpty) {
                final totalCurrent = calculations.fold(
                  0.0,
                  (prev, curr) => prev + curr.result,
                );
                final needed =
                    (target * (calculations.length + 1)) - totalCurrent;
                setState(() {
                  _requiredGpa = needed;
                });
              } else {
                setState(() {
                  _requiredGpa = null;
                });
              }
            },
          ),
          if (_requiredGpa != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _requiredGpa! <= 10.0 && _requiredGpa! >= 0
                      ? [
                          const Color(0xFF11998e).withAlpha(50),
                          const Color(0xFF38ef7d).withAlpha(50),
                        ]
                      : [
                          const Color(0xFFf5576c).withAlpha(50),
                          const Color(0xFFf093fb).withAlpha(50),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _requiredGpa! <= 10.0 && _requiredGpa! >= 0
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _requiredGpa! <= 10.0 && _requiredGpa! >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _requiredGpa! <= 10.0 && _requiredGpa! >= 0
                          ? 'You need ${_requiredGpa!.toStringAsFixed(2)} GPA in your next semester to reach your goal!'
                          : 'This target is not achievable in one semester. Try a lower target.',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickTargets(
    List<CalculationRecord> calculations,
    double currentAverage,
  ) {
    final targets = [7.0, 7.5, 8.0, 8.5, 9.0, 9.5];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Targets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: targets.map((target) {
              double required = 0;
              bool achievable = false;

              if (calculations.isNotEmpty) {
                final totalCurrent = calculations.fold(
                  0.0,
                  (prev, curr) => prev + curr.result,
                );
                required = (target * (calculations.length + 1)) - totalCurrent;
                achievable = required <= 10.0 && required >= 0;
              }

              final alreadyAchieved = currentAverage >= target;

              return GestureDetector(
                onTap: () {
                  _targetGpaController.text = target.toString();
                  if (calculations.isNotEmpty) {
                    final totalCurrent = calculations.fold(
                      0.0,
                      (prev, curr) => prev + curr.result,
                    );
                    setState(() {
                      _requiredGpa =
                          (target * (calculations.length + 1)) - totalCurrent;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: alreadyAchieved
                        ? const LinearGradient(
                            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                          )
                        : achievable
                        ? const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey[400]!, Colors.grey[500]!],
                          ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        target.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (alreadyAchieved)
                        const Text(
                          '✓ Done',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        )
                      else if (calculations.isNotEmpty)
                        Text(
                          achievable
                              ? 'Need ${required.toStringAsFixed(1)}'
                              : 'Hard',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(List<CalculationRecord> calculations) {
    final achievements = <Map<String, dynamic>>[];

    if (calculations.isNotEmpty) {
      final average =
          calculations.fold(0.0, (prev, curr) => prev + curr.result) /
          calculations.length;
      final highest = calculations.fold(
        0.0,
        (prev, curr) => curr.result > prev ? curr.result : prev,
      );

      // First calculation
      achievements.add({
        'icon': Icons.star,
        'title': 'First Step',
        'desc': 'Completed first calculation',
        'unlocked': true,
        'color': Colors.amber,
      });

      // 5 calculations
      achievements.add({
        'icon': Icons.local_fire_department,
        'title': 'Getting Started',
        'desc': 'Complete 5 calculations',
        'unlocked': calculations.length >= 5,
        'color': Colors.orange,
      });

      // 10 calculations
      achievements.add({
        'icon': Icons.military_tech,
        'title': 'Dedicated',
        'desc': 'Complete 10 calculations',
        'unlocked': calculations.length >= 10,
        'color': Colors.purple,
      });

      // High achiever
      achievements.add({
        'icon': Icons.emoji_events,
        'title': 'High Achiever',
        'desc': 'Get 9.0+ GPA',
        'unlocked': highest >= 9.0,
        'color': Colors.green,
      });

      // Perfect score
      achievements.add({
        'icon': Icons.workspace_premium,
        'title': 'Perfect Score',
        'desc': 'Achieve 10.0 GPA',
        'unlocked': highest >= 10.0,
        'color': Colors.blue,
      });

      // Consistent
      achievements.add({
        'icon': Icons.balance,
        'title': 'Consistent',
        'desc': 'Maintain 8.0+ average',
        'unlocked': average >= 8.0,
        'color': Colors.teal,
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf9d423), Color(0xFFff4e50)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Achievements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((achievement) {
              final unlocked = achievement['unlocked'] as bool;
              return Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked
                      ? (achievement['color'] as Color).withAlpha(25)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: unlocked
                        ? (achievement['color'] as Color).withAlpha(100)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      achievement['icon'] as IconData,
                      color: unlocked
                          ? achievement['color'] as Color
                          : Colors.grey[400],
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement['desc'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<CalculationRecord> _getFilteredData(
    CalculationHistoryProvider provider,
  ) {
    if (_selectedFilter == 'All') {
      return provider.calculations;
    }
    return provider.calculations
        .where((c) => c.calculationType == _selectedFilter)
        .toList();
  }

  String _getGrade(double gpa) {
    if (gpa >= 9.0) return 'A+';
    if (gpa >= 8.0) return 'A';
    if (gpa >= 7.0) return 'B+';
    if (gpa >= 6.0) return 'B';
    if (gpa >= 5.0) return 'C';
    if (gpa >= 4.0) return 'D';
    return 'F';
  }

  Color _getGradeColor(double gpa) {
    if (gpa >= 9.0) return Colors.green;
    if (gpa >= 8.0) return Colors.teal;
    if (gpa >= 7.0) return Colors.blue;
    if (gpa >= 6.0) return Colors.orange;
    if (gpa >= 5.0) return Colors.deepOrange;
    return Colors.red;
  }

  Future<void> _exportPdf(CalculationHistoryProvider provider) async {
    final calculations = provider.calculations;
    final average =
        calculations.fold(0.0, (prev, curr) => prev + curr.result) /
        calculations.length;
    final highest = calculations.fold(
      0.0,
      (prev, curr) => curr.result > prev ? curr.result : prev,
    );
    final lowest = calculations.fold(
      double.infinity,
      (prev, curr) => curr.result < prev ? curr.result : prev,
    );

    await PDFExportService.generateAndPrintAnalyticsReport(
      calculations: calculations,
      stats: {
        'average': average,
        'highest': highest,
        'lowest': lowest == double.infinity ? 0.0 : lowest,
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withAlpha(100),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withAlpha(200), size: 24),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200)),
          ),
        ],
      ),
    );
  }
}

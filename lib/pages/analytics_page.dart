import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculation_history_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/calculation_model.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedFilter = 'All'; // All, CGPA, SGPA, PERCENTAGE

  String _formatDate(DateTime timestamp) {
    final d = timestamp.day.toString().padLeft(2, '0');
    final m = timestamp.month.toString().padLeft(2, '0');
    final y = timestamp.year.toString();
    return '$d/$m/$y';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalculationHistoryProvider>().loadCalculations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isTeacher = authProvider.currentUser?.role == 'teacher';
    final teacherColors = themeProvider.teacherGradientColors;
    final teacherAccent = themeProvider.teacherAccentColor;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: isTeacher
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: teacherColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              )
            : null,
        backgroundColor: isTeacher ? Colors.transparent : null,
        foregroundColor: isTeacher ? Colors.white : null,
        title: const Text('Analytics Dashboard'),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Consumer<CalculationHistoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: isTeacher ? teacherAccent : null,
              ),
            );
          }

          if (provider.calculations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No calculations yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start calculating to see analytics',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          List<CalculationRecord> filteredData = _selectedFilter == 'All'
              ? provider.calculations
              : provider.calculations
                    .where(
                      (c) =>
                          c.calculationType.trim().toUpperCase() ==
                          _selectedFilter.toUpperCase(),
                    )
                    .toList();

          filteredData.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Filter buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'CGPA', 'SGPA', 'PERCENTAGE'].map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Cards
              _buildStatisticsCards(context, filteredData),
              const SizedBox(height: 24),

              // Recent Calculations
              _buildRecentCalculations(context, filteredData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards(
    BuildContext context,
    List<CalculationRecord> data,
  ) {
    if (data.isEmpty) return const SizedBox();

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

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Average',
            value: average.toStringAsFixed(2),
            color: Colors.blue,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Highest',
            value: highest.toStringAsFixed(2),
            color: Colors.green,
            icon: Icons.star,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Lowest',
            value: lowest == double.infinity
                ? '0.00'
                : lowest.toStringAsFixed(2),
            color: Colors.orange,
            icon: Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCalculations(
    BuildContext context,
    List<CalculationRecord> data,
  ) {
    if (data.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Calculations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.take(5).length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final record = data.take(5).toList()[index];
              final type = record.calculationType.trim().toUpperCase();
              final isCgpa = type == 'CGPA';
              final isSgpa = type == 'SGPA';
              final tileColor = isCgpa
                  ? Colors.blue
                  : isSgpa
                  ? Colors.purple
                  : Colors.orange;
              final tileIcon = isCgpa
                  ? Icons.calculate_rounded
                  : isSgpa
                  ? Icons.school_rounded
                  : Icons.percent_rounded;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tileColor.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(tileIcon, color: tileColor),
                ),
                title: Text(
                  '${record.calculationType}: ${record.result.toStringAsFixed(2)}',
                ),
                subtitle: Text(
                  type == 'CGPA'
                      ? '${record.semesterName} • ${(record.result * 9.5).clamp(0, 100).toStringAsFixed(1)}%'
                      : type == 'PERCENTAGE'
                      ? '${record.semesterName} • from CGPA'
                      : record.semesterName,
                ),
                trailing: Text(
                  _formatDate(record.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculation_model.dart';
import '../models/student_model.dart';
import '../providers/calculation_history_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/student_grade_provider.dart';

class StudentPercentagePage extends StatefulWidget {
  final Student student;

  const StudentPercentagePage({super.key, required this.student});

  @override
  State<StudentPercentagePage> createState() => _StudentPercentagePageState();
}

class _StudentPercentagePageState extends State<StudentPercentagePage> {
  final _cgpaController = TextEditingController();
  double? _percentage;
  String _selectedScale = '10';

  final Map<String, double> _conversionFactors = {
    '10': 9.5, // percentage = cgpa * 9.5
    '4': 25.0, // percentage = cgpa * 25
  };

  @override
  void initState() {
    super.initState();
    // Pre-fill with student's current CGPA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudentGradeProvider>(
        context,
        listen: false,
      );
      final gradeData = provider.getOrCreateGradeData(widget.student.id);
      if (gradeData.cgpa > 0) {
        _cgpaController.text = gradeData.cgpa.toStringAsFixed(2);
        _calculatePercentage();
      }
    });
  }

  @override
  void dispose() {
    _cgpaController.dispose();
    super.dispose();
  }

  Future<void> _calculatePercentage({bool saveToHistory = false}) async {
    final cgpa = double.tryParse(_cgpaController.text);
    if (cgpa == null) {
      setState(() => _percentage = null);
      return;
    }

    final factor = _conversionFactors[_selectedScale] ?? 9.5;
    setState(() {
      _percentage = cgpa * factor;
      if (_percentage! > 100) _percentage = 100;
    });

    if (!saveToHistory) return;

    final semesterName = '${_selectedScale}-Point Scale';

    await Provider.of<CalculationHistoryProvider>(
      context,
      listen: false,
    ).addCalculation(
      CalculationRecord(
        calculationType: 'PERCENTAGE',
        result: _percentage!,
        subjects: [
          Subject(
            name: 'CGPA',
            score: cgpa,
            outOf: double.tryParse(_selectedScale) ?? 10,
            credit: 1,
          ),
        ],
        timestamp: DateTime.now(),
        semesterName: semesterName,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percentage conversion saved to history'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

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
          'Percentage Converter',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Student Info Card
            _buildStudentCard(isDark),
            const SizedBox(height: 24),

            // Conversion Input Card
            _buildConversionCard(isDark),
            const SizedBox(height: 24),

            // Result Card
            if (_percentage != null) _buildResultCard(isDark),

            // Info Card
            const SizedBox(height: 24),
            _buildInfoCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(bool isDark) {
    return Consumer<StudentGradeProvider>(
      builder: (context, provider, _) {
        final gradeData = provider.getOrCreateGradeData(widget.student.id);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB347).withOpacity(0.3),
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
                    widget.student.name.isNotEmpty
                        ? widget.student.name[0].toUpperCase()
                        : 'S',
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
                      widget.student.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.student.rollNumber,
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
                    gradeData.cgpa.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Current CGPA',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Convert CGPA to Percentage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Scale Selection
          Text(
            'CGPA Scale',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildScaleButton('10', '10-Point Scale', isDark),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildScaleButton('4', '4-Point Scale', isDark)),
            ],
          ),
          const SizedBox(height: 20),

          // CGPA Input
          TextField(
            controller: _cgpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              labelText: 'Enter CGPA',
              labelStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey,
              ),
              prefixIcon: Icon(
                Icons.calculate_outlined,
                color: isDark ? Colors.white60 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFB347)),
              ),
            ),
            onChanged: (_) => _calculatePercentage(),
          ),
          const SizedBox(height: 20),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _calculatePercentage(saveToHistory: true),
              icon: const Icon(Icons.percent_rounded),
              label: const Text('Calculate Percentage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB347),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleButton(String scale, String label, bool isDark) {
    final isSelected = _selectedScale == scale;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedScale = scale);
        _calculatePercentage();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFB347).withOpacity(0.1)
              : isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB347) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              scale,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFFFFB347)
                    : isDark
                    ? Colors.white60
                    : Colors.grey[600],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getPercentageColor(_percentage!),
            _getPercentageColor(_percentage!).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getPercentageColor(_percentage!).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Equivalent Percentage',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _percentage!.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '%',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPerformanceLabel(_percentage!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Conversion Formula',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormulaItem(
            '10-Point Scale',
            'Percentage = CGPA × 9.5',
            isDark,
          ),
          const SizedBox(height: 12),
          _buildFormulaItem('4-Point Scale', 'Percentage = CGPA × 25', isDark),
        ],
      ),
    );
  }

  Widget _buildFormulaItem(String title, String formula, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  formula,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.teal;
    if (percentage >= 70) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 50) return Colors.deepOrange;
    return Colors.red;
  }

  String _getPerformanceLabel(double percentage) {
    if (percentage >= 90) return 'Outstanding Performance';
    if (percentage >= 80) return 'Excellent Performance';
    if (percentage >= 70) return 'Very Good Performance';
    if (percentage >= 60) return 'Good Performance';
    if (percentage >= 50) return 'Average Performance';
    return 'Needs Improvement';
  }
}

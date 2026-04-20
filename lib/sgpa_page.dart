import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/calculation_model.dart';
import 'providers/calculation_history_provider.dart';

class SGPAPage extends StatefulWidget {
  const SGPAPage({super.key});

  @override
  State<SGPAPage> createState() => _SGPAPageState();
}

class _SGPAPageState extends State<SGPAPage> {
  final List<Map<String, TextEditingController>> subjects = [];
  double sgpa = 0;

  @override
  void initState() {
    super.initState();
    addSubject();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLatestSavedSgpa();
    });
  }

  Future<void> _loadLatestSavedSgpa() async {
    final provider = context.read<CalculationHistoryProvider>();
    await provider.loadCalculations();
    final sgpaRecords = provider.getCalculationsByType('SGPA');
    if (!mounted || sgpaRecords.isEmpty) return;

    sgpaRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      sgpa = sgpaRecords.first.result;
    });
  }

  void addSubject() {
    setState(() {
      subjects.add({
        "name": TextEditingController(),
        "score": TextEditingController(),
        "outOf": TextEditingController(text: "100"),
        "credit": TextEditingController(text: "1"),
      });
    });
  }

  void removeSubject(int index) {
    if (subjects.length > 1) {
      setState(() {
        subjects.removeAt(index);
      });
    }
  }

  Future<void> calculateSGPA() async {
    double totalGradePoints = 0;
    double totalCredits = 0;

    List<Subject> subjectsList = [];

    for (int i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      final name = subject["name"]!.text;
      final scoreText = subject["score"]!.text.trim();
      final outOfText = subject["outOf"]!.text.trim();
      final creditText = subject["credit"]!.text.trim();

      if (scoreText.isEmpty || outOfText.isEmpty || creditText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill Score, Out of and Credit for Subject ${i + 1}.',
            ),
          ),
        );
        return;
      }

      final score = double.tryParse(scoreText);
      final outOf = double.tryParse(outOfText);
      final credit = double.tryParse(creditText);

      if (score == null || outOf == null || credit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enter valid numeric values for Subject ${i + 1}.'),
          ),
        );
        return;
      }

      if (outOf <= 0 || credit <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Out of and Credit must be greater than 0 for Subject ${i + 1}.',
            ),
          ),
        );
        return;
      }

      if (score < 0 || score > outOf) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Score must be between 0 and Out of for Subject ${i + 1}.',
            ),
          ),
        );
        return;
      }

      subjectsList.add(
        Subject(
          name: name.isEmpty ? 'Subject' : name,
          score: score,
          outOf: outOf,
          credit: credit,
        ),
      );

      final percentage = (score / outOf) * 100;
      double gradePoint = 0;

      if (percentage >= 90) {
        gradePoint = 10; // O  - Outstanding
      } else if (percentage >= 80)
        gradePoint = 9; // A+ - Excellent
      else if (percentage >= 70)
        gradePoint = 8; // A  - Very Good
      else if (percentage >= 60)
        gradePoint = 7; // B+ - Good
      else if (percentage >= 50)
        gradePoint = 6; // B  - Above Average
      else if (percentage >= 45)
        gradePoint = 5; // C  - Average
      else if (percentage >= 40)
        gradePoint = 4; // P  - Pass
      // else gradePoint stays 0 (F - Fail, below 40%)

      totalGradePoints += gradePoint * credit;
      totalCredits += credit;
    }

    if (totalCredits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one subject with valid credit.'),
        ),
      );
      return;
    }

    final calculatedSGPA = totalCredits > 0
        ? totalGradePoints / totalCredits
        : 0.0;

    setState(() {
      sgpa = calculatedSGPA;
    });

    // Save to database
    final record = CalculationRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      calculationType: 'SGPA',
      result: calculatedSGPA,
      subjects: subjectsList,
      timestamp: DateTime.now(),
      semesterName: 'Semester ${DateTime.now().month}',
    );

    await context.read<CalculationHistoryProvider>().addCalculation(record);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SGPA calculated and saved!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void clearAll() {
    setState(() {
      subjects.clear();
      addSubject();
      sgpa = 0;
    });
  }

  String _getGradeMessage(double sgpa) {
    if (sgpa >= 9.0) return 'Outstanding! 🌟';
    if (sgpa >= 7.5) return 'Excellent! 🎯';
    if (sgpa >= 6.0) return 'Great! 👍';
    if (sgpa > 0) return 'Keep Improving! 💪';
    return 'Calculate to get started';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SGPA Calculator'),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: clearAll,
            tooltip: 'Clear All',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addSubject,
        tooltip: 'Add Subject',
        child: const Icon(Icons.add_rounded),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFFEF3C7),
              const Color(0xFFFEED7E),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Result Card with Gradient
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withAlpha(76),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your SGPA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(200),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: _GaugeArcPainter(value: sgpa, maxValue: 10),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sgpa.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                '/ 10',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withAlpha(180),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getGradeMessage(sgpa),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (sgpa > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Percentage: ${(sgpa * 9.5).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Subjects List
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Text(
                        'Add subjects to calculate SGPA',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        return _buildSubjectCard(index);
                      },
                    ),
            ),

            // Calculate Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: calculateSGPA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_rounded, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'CALCULATE SGPA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => removeSubject(index),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withAlpha(204),
                            const Color(0xFFFBBF24).withAlpha(204),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subjects[index]["name"]!.text.isEmpty
                                ? 'Enter subject name'
                                : subjects[index]["name"]!.text,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (subjects.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () => removeSubject(index),
                        splashRadius: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjects[index]["name"],
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    prefixIcon: const Icon(Icons.book_rounded),
                    hintText: 'e.g., Physics',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subjects[index]["score"],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Marks',
                          prefixIcon: Icon(Icons.grade_rounded),
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: subjects[index]["outOf"],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Out of',
                          prefixIcon: Icon(Icons.trending_up_rounded),
                          hintText: '100',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjects[index]["credit"],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Credits',
                    prefixIcon: Icon(Icons.star_rounded),
                    hintText: '0',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  final double value;
  final double maxValue;

  const _GaugeArcPainter({required this.value, required this.maxValue});

  static const double _startAngle = 2.5;
  static const double _totalSweep = 4.6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _totalSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = Colors.white.withAlpha(40)
        ..strokeCap = StrokeCap.round,
    );

    final sweepProgress = (value / maxValue).clamp(0.0, 1.0);
    if (sweepProgress > 0) {
      final valueSweep = _totalSweep * sweepProgress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        valueSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withAlpha(20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        valueSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: const [
              Color(0xFF74F7FF),
              Color(0xFFA29BFE),
              Color(0xFFFF9FF3),
              Color(0xFF74F7FF),
            ],
            stops: const [0.0, 0.35, 0.7, 1.0],
            transform: GradientRotation(_startAngle),
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_GaugeArcPainter old) =>
      old.value != value || old.maxValue != maxValue;
}

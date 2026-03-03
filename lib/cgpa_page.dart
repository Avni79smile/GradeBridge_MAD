import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/calculation_model.dart';
import 'providers/calculation_history_provider.dart';

class CGPAPage extends StatefulWidget {
  const CGPAPage({super.key});

  @override
  State<CGPAPage> createState() => _CGPAPageState();
}

class _CGPAPageState extends State<CGPAPage> {
  final List<Map<String, TextEditingController>> subjects = [];
  double cgpa = 0;

  @override
  void initState() {
    super.initState();
    addSubject();
  }

  void addSubject() {
    setState(() {
      subjects.add({
        "name": TextEditingController(),
        "score": TextEditingController(),
        "outOf": TextEditingController(text: "100"),
        "credit": TextEditingController(),
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

  void calculateCGPA() {
    double totalGradePoints = 0;
    double totalCredits = 0;

    List<Subject> subjectsList = [];

    for (var subject in subjects) {
      final name = subject["name"]!.text;
      final score = double.tryParse(subject["score"]!.text) ?? 0;
      final outOf = double.tryParse(subject["outOf"]!.text) ?? 100;
      final credit = double.tryParse(subject["credit"]!.text) ?? 0;

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
        gradePoint = 10;
      } else if (percentage >= 80)
        gradePoint = 9;
      else if (percentage >= 70)
        gradePoint = 8;
      else if (percentage >= 60)
        gradePoint = 7;
      else if (percentage >= 50)
        gradePoint = 6;
      else if (percentage >= 40)
        gradePoint = 5;
      else if (percentage >= 30)
        gradePoint = 4;

      totalGradePoints += gradePoint * credit;
      totalCredits += credit;
    }

    final calculatedCGPA =
        (totalCredits > 0 ? totalGradePoints / totalCredits : 0) as double;

    setState(() {
      cgpa = calculatedCGPA;
    });

    // Save to database
    final record = CalculationRecord(
      calculationType: 'CGPA',
      result: calculatedCGPA,
      subjects: subjectsList,
      timestamp: DateTime.now(),
      semesterName: 'Semester ${DateTime.now().month}',
    );

    context.read<CalculationHistoryProvider>().addCalculation(record);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CGPA calculated and saved!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void clearAll() {
    setState(() {
      subjects.clear();
      addSubject();
      cgpa = 0;
    });
  }

  String _getGradeMessage(double cgpa) {
    if (cgpa >= 9.0) return 'Outstanding! 🌟';
    if (cgpa >= 7.5) return 'Excellent! 🎯';
    if (cgpa >= 6.0) return 'Great! 👍';
    if (cgpa > 0) return 'Keep Improving! 💪';
    return 'Calculate to get started';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
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
              const Color(0xFFF1F5F9),
              const Color(0xFFEFF6FF),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Premium Result Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4F46E5),
                    const Color(0xFF7C3AED),
                    const Color(0xFFA78BFA),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withAlpha(80),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withAlpha(40),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withAlpha(50),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Text(
                      'Your CGPA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(220),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white.withAlpha(200)],
                      ).createShader(bounds),
                      child: Text(
                        cgpa.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(30),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getGradeMessage(cgpa),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subjects List
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 56,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Add subjects to calculate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        return _buildSubjectCard(index);
                      },
                    ),
            ),

            // Calculate Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: calculateCGPA,
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    shadowColor: const Color(0xFF4F46E5).withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_rounded, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'CALCULATE CGPA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            'Subject ${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subjects[index]["name"]!.text.isEmpty
                                ? 'Enter subject name'
                                : subjects[index]["name"]!.text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subjects[index]["name"],
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    prefixIcon: Icon(Icons.subject_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjects[index]["score"],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Score Obtained',
                    prefixIcon: Icon(Icons.grade_rounded),
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjects[index]["outOf"],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Out Of',
                    prefixIcon: Icon(Icons.trending_up_rounded),
                    hintText: '100',
                  ),
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

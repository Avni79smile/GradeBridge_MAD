import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/calculation_model.dart';
import 'providers/calculation_history_provider.dart';

class CGPAPercentagePage extends StatefulWidget {
  const CGPAPercentagePage({super.key});

  @override
  State<CGPAPercentagePage> createState() => _CGPAPercentagePageState();
}

class _CGPAPercentagePageState extends State<CGPAPercentagePage> {
  final List<Map<String, TextEditingController>> subjects = [];
  double cgpa = 0;
  double percentage = 0;

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

  void calculateBoth() {
    double totalGradePoints = 0;
    double totalCredits = 0;
    double totalScored = 0;
    double totalOutOf = 0;
    List<Subject> subjectsList = [];

    for (var subject in subjects) {
      final score = double.tryParse(subject["score"]!.text) ?? 0;
      final outOf = double.tryParse(subject["outOf"]!.text) ?? 100;
      final credit = double.tryParse(subject["credit"]!.text) ?? 0;

      final subjectPercentage = (score / outOf) * 100;
      double gradePoint = 0;

      if (subjectPercentage >= 90) {
        gradePoint = 10;
      } else if (subjectPercentage >= 80)
        gradePoint = 9;
      else if (subjectPercentage >= 70)
        gradePoint = 8;
      else if (subjectPercentage >= 60)
        gradePoint = 7;
      else if (subjectPercentage >= 50)
        gradePoint = 6;
      else if (subjectPercentage >= 40)
        gradePoint = 5;
      else if (subjectPercentage >= 30)
        gradePoint = 4;

      totalGradePoints += gradePoint * credit;
      totalCredits += credit;
      totalScored += score;
      totalOutOf += outOf;

      // Create Subject object for history
      subjectsList.add(
        Subject(
          name: subject["name"]!.text.isEmpty
              ? 'Subject ${subjectsList.length + 1}'
              : subject["name"]!.text,
          score: score,
          outOf: outOf,
          credit: credit,
        ),
      );
    }

    double calculatedCGPA = totalCredits > 0
        ? totalGradePoints / totalCredits
        : 0;

    setState(() {
      cgpa = calculatedCGPA;
      percentage = totalOutOf > 0 ? (totalScored / totalOutOf) * 100 : 0;
    });

    // Save calculation to history
    final newRecord = CalculationRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      calculationType: 'CGPA',
      result: calculatedCGPA,
      subjects: subjectsList,
      timestamp: DateTime.now(),
      semesterName: 'CGPA - ${DateTime.now().toString().split(' ')[0]}',
    );

    context.read<CalculationHistoryProvider>().addCalculation(newRecord);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CGPA calculated and saved to history!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void clearAll() {
    setState(() {
      subjects.clear();
      addSubject();
      cgpa = 0;
      percentage = 0;
    });
  }

  String getGrade(double cgpa) {
    if (cgpa >= 9.0) return 'A+';
    if (cgpa >= 8.0) return 'A';
    if (cgpa >= 7.0) return 'B+';
    if (cgpa >= 6.0) return 'B';
    if (cgpa >= 5.0) return 'C+';
    if (cgpa >= 4.0) return 'C';
    return 'F';
  }

  String _getPercentageGrade(double percentage) {
    if (percentage >= 90) return 'A+ (Excellent)';
    if (percentage >= 80) return 'A (Very Good)';
    if (percentage >= 70) return 'B+ (Good)';
    if (percentage >= 60) return 'B (Above Average)';
    if (percentage >= 50) return 'C+ (Average)';
    if (percentage >= 40) return 'C (Pass)';
    return 'F (Fail)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA + Percentage'),
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
              const Color(0xFFFDF2F8),
              const Color(0xFFFBCFE8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Results Cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildResultCard(
                      'CGPA',
                      cgpa.toStringAsFixed(2),
                      getGrade(cgpa),
                      const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildResultCard(
                      'Percentage',
                      '${percentage.toStringAsFixed(2)}%',
                      _getPercentageGrade(percentage),
                      const Color(0xFFEC4899),
                    ),
                  ),
                ],
              ),
            ),

            // Subjects List
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Text(
                        'Add subjects to calculate both',
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
                  onPressed: calculateBoth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
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
                        'CALCULATE BOTH',
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

  Widget _buildResultCard(
    String title,
    String value,
    String grade,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withAlpha(230), color.withAlpha(180)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(200),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(220),
              ),
            ),
          ),
        ],
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
                            const Color(0xFFEC4899).withAlpha(204),
                            const Color(0xFFF472B6).withAlpha(204),
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
                    hintText: 'e.g., English',
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

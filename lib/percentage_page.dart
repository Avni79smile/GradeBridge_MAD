import 'package:flutter/material.dart';

class PercentagePage extends StatefulWidget {
  const PercentagePage({super.key});

  @override
  State<PercentagePage> createState() => _PercentagePageState();
}

class _PercentagePageState extends State<PercentagePage> {
  final List<Map<String, TextEditingController>> subjects = [];
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

  void calculatePercentage() {
    double totalScored = 0;
    double totalOutOf = 0;

    for (int i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      final scoreText = subject["score"]!.text.trim();
      final outOfText = subject["outOf"]!.text.trim();

      if (scoreText.isEmpty || outOfText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill Marks and Total Marks for Subject ${i + 1}.',
            ),
          ),
        );
        return;
      }

      final score = double.tryParse(scoreText);
      final outOf = double.tryParse(outOfText);

      if (score == null || outOf == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enter valid numeric values for Subject ${i + 1}.'),
          ),
        );
        return;
      }

      if (outOf <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total Marks must be greater than 0 for Subject ${i + 1}.',
            ),
          ),
        );
        return;
      }

      if (score < 0 || score > outOf) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marks must be between 0 and Total Marks for Subject ${i + 1}.',
            ),
          ),
        );
        return;
      }

      totalScored += score;
      totalOutOf += outOf;
    }

    if (totalOutOf <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid subject entry.'),
        ),
      );
      return;
    }

    setState(() {
      percentage = totalOutOf > 0 ? (totalScored / totalOutOf) * 100 : 0;
    });
  }

  void clearAll() {
    setState(() {
      subjects.clear();
      addSubject();
      percentage = 0;
    });
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'A+ (Excellent)';
    if (percentage >= 80) return 'A (Very Good)';
    if (percentage >= 70) return 'B+ (Good)';
    if (percentage >= 60) return 'B (Above Average)';
    if (percentage >= 50) return 'C+ (Average)';
    if (percentage >= 40) return 'C (Pass)';
    return 'F (Fail)';
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return const Color(0xFF10B981);
    if (percentage >= 80) return const Color(0xFF34D399);
    if (percentage >= 70) return const Color(0xFF3B82F6);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    if (percentage >= 50) return const Color(0xFFFB923C);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Percentage Calculator'),
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
              const Color(0xFFF0FDF4),
              const Color(0xFFDCFCE7),
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
                  colors: [
                    Color(_getPercentageColor(percentage).value),
                    Color(_getPercentageColor(percentage).value).withAlpha(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _getPercentageColor(percentage).withAlpha(76),
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
                      'Overall Percentage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(200),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${percentage.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
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
                        _getGrade(percentage),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
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
                      child: Text(
                        'Add subjects to calculate percentage',
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
                  onPressed: calculatePercentage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
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
                        'CALCULATE PERCENTAGE',
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
                            const Color(0xFF10B981).withAlpha(204),
                            const Color(0xFF34D399).withAlpha(204),
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
                    hintText: 'e.g., Chemistry',
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
                          labelText: 'Marks Obtained',
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
                          labelText: 'Total Marks',
                          prefixIcon: Icon(Icons.trending_up_rounded),
                          hintText: '100',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

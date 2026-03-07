import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../models/student_grade_model.dart';
import '../providers/theme_provider.dart';
import '../providers/student_grade_provider.dart';

class _SubjectEntry {
  final nameController = TextEditingController();
  final obtainedController = TextEditingController();
  final totalController = TextEditingController();
  final creditsController = TextEditingController();

  void dispose() {
    nameController.dispose();
    obtainedController.dispose();
    totalController.dispose();
    creditsController.dispose();
  }
}

class StudentSgpaPage extends StatefulWidget {
  final Student student;
  final String? initialSemesterName;

  /// When set, new subjects are appended to this semester instead of creating a new one.
  final String? existingSemesterId;
  const StudentSgpaPage({
    super.key,
    required this.student,
    this.initialSemesterName,
    this.existingSemesterId,
  });

  @override
  State<StudentSgpaPage> createState() => _StudentSgpaPageState();
}

class _StudentSgpaPageState extends State<StudentSgpaPage> {
  final _semNameController = TextEditingController();
  final List<_SubjectEntry> _entries = [_SubjectEntry()];
  double? _result;
  bool _calculated = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSemesterName != null &&
        widget.initialSemesterName!.isNotEmpty) {
      _semNameController.text = widget.initialSemesterName!;
    }
  }

  static const Map<String, double> _gradePoints = {
    'O': 10.0,
    'A+': 9.0,
    'A': 8.0,
    'B+': 7.0,
    'B': 6.0,
    'C': 5.0,
    'P': 4.0,
    'F': 0.0,
  };

  @override
  void dispose() {
    _semNameController.dispose();
    for (final e in _entries) e.dispose();
    super.dispose();
  }

  String _marksToGrade(double obtained, double total) {
    final pct = total > 0 ? (obtained / total) * 100 : 0;
    if (pct >= 90) return 'O';
    if (pct >= 80) return 'A+';
    if (pct >= 70) return 'A';
    if (pct >= 60) return 'B+';
    if (pct >= 50) return 'B';
    if (pct >= 45) return 'C';
    if (pct >= 40) return 'P';
    return 'F';
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'O':
        return const Color(0xFF10B981);
      case 'A+':
        return const Color(0xFF059669);
      case 'A':
        return const Color(0xFF3B82F6);
      case 'B+':
        return const Color(0xFF6366F1);
      case 'B':
        return const Color(0xFFF59E0B);
      case 'C':
        return const Color(0xFFEF4444);
      case 'P':
        return const Color(0xFF78716C);
      default:
        return const Color(0xFFDC2626);
    }
  }

  void _calculate() {
    double totalPoints = 0;
    double totalCredits = 0;

    for (final e in _entries) {
      final name = e.nameController.text.trim();
      final obtained = double.tryParse(e.obtainedController.text.trim());
      final total = double.tryParse(e.totalController.text.trim());
      final credits = int.tryParse(e.creditsController.text.trim());

      if (name.isEmpty ||
          obtained == null ||
          total == null ||
          credits == null ||
          credits <= 0 ||
          total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all subject fields correctly'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      final grade = _marksToGrade(obtained, total);
      totalPoints += (_gradePoints[grade] ?? 0.0) * credits;
      totalCredits += credits;
    }

    setState(() {
      _result = totalCredits > 0 ? totalPoints / totalCredits : 0;
      _calculated = true;
    });
  }

  void _save() {
    final subjects = <StudentSubject>[];
    for (final e in _entries) {
      final name = e.nameController.text.trim();
      final obtained = double.tryParse(e.obtainedController.text.trim());
      final total = double.tryParse(e.totalController.text.trim());
      final credits = int.tryParse(e.creditsController.text.trim());
      if (name.isEmpty ||
          obtained == null ||
          total == null ||
          credits == null ||
          credits <= 0 ||
          total <= 0)
        continue;
      final grade = _marksToGrade(obtained, total);
      subjects.add(
        StudentSubject(
          name: name,
          credits: credits,
          grade: grade,
          gradePoints: _gradePoints[grade] ?? 0,
        ),
      );
    }

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one complete subject'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final provider = Provider.of<StudentGradeProvider>(context, listen: false);

    if (widget.existingSemesterId != null) {
      // Append mode: add subjects to the existing semester
      provider.appendSubjectsToSemester(
        widget.student.id,
        widget.existingSemesterId!,
        subjects,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Subjects added to semester!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() {
        for (final e in _entries) e.dispose();
        _entries.clear();
        _entries.add(_SubjectEntry());
        _result = null;
        _calculated = false;
      });
      return;
    }

    // New semester mode
    double tp = 0, tc = 0;
    for (final s in subjects) {
      tp += s.gradePoints * s.credits;
      tc += s.credits;
    }
    final sgpa = tc > 0 ? tp / tc : 0.0;

    provider.addSemester(
      widget.student.id,
      StudentSemester(
        semesterName: _semNameController.text.trim().isNotEmpty
            ? _semNameController.text.trim()
            : 'Semester',
        subjects: subjects,
        sgpa: sgpa,
        toolUsed: 'sgpa',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Semester saved successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    setState(() {
      _semNameController.clear();
      for (final e in _entries) e.dispose();
      _entries.clear();
      _entries.add(_SubjectEntry());
      _result = sgpa;
      _calculated = false;
    });
  }

  void _addEntry() => setState(() => _entries.add(_SubjectEntry()));

  void _removeEntry(int index) {
    if (_entries.length == 1) return;
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

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
          'SGPA Calculator',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultCard(isDark),
            const SizedBox(height: 24),
            _buildInputCard(isDark),
            const SizedBox(height: 24),
            _buildCalculateButton(),
            const SizedBox(height: 16),
            _buildSaveButton(isDark),
            const SizedBox(height: 24),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF00B4DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C9A7).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.student.name,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _result != null ? _result!.toStringAsFixed(2) : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'SGPA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semester Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _semNameController,
            readOnly: widget.existingSemesterId != null,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'e.g. Semester 1',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: const Icon(Icons.calendar_today_rounded),
              suffixIcon: widget.existingSemesterId != null
                  ? const Icon(Icons.lock_outline, size: 18)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Subjects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_entries.length, (i) => _buildSubjectRow(isDark, i)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add More Subject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00C9A7),
                side: const BorderSide(color: Color(0xFF00C9A7)),
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFF00B4DB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9A7).withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_rounded, size: 22),
          label: const Text(
            'CALCULATE SGPA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    final isAppend = widget.existingSemesterId != null;
    return Opacity(
      opacity: _calculated ? 1.0 : 0.5,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          onPressed: _calculated ? _save : null,
          icon: Icon(
            isAppend ? Icons.add_circle_rounded : Icons.save_rounded,
            size: 22,
          ),
          label: Text(
            isAppend ? 'ADD SUBJECTS TO SEMESTER' : 'SAVE SEMESTER',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF10B981).withAlpha(80),
            disabledForegroundColor: Colors.white60,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectRow(bool isDark, int index) {
    final entry = _entries[index];
    final obtained = double.tryParse(entry.obtainedController.text.trim());
    final total = double.tryParse(entry.totalController.text.trim());
    String? grade;
    if (obtained != null && total != null && total > 0) {
      grade = _marksToGrade(obtained, total);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9A7).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF00C9A7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Subject ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (grade != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _gradeColor(grade).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      color: _gradeColor(grade),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (_entries.length > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeEntry(index),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: entry.nameController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Subject Name',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: entry.obtainedController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Marks',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white54 : Colors.black38,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: entry.totalController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Out of',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry.creditsController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cr',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/analysis_pdf_record.dart';
import '../models/student_model.dart';
import '../services/analysis_pdf_service.dart';

class AnalysisPdfHistoryPage extends StatefulWidget {
  final Student student;

  const AnalysisPdfHistoryPage({super.key, required this.student});

  @override
  State<AnalysisPdfHistoryPage> createState() => _AnalysisPdfHistoryPageState();
}

class _AnalysisPdfHistoryPageState extends State<AnalysisPdfHistoryPage> {
  late Future<List<AnalysisPdfRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<AnalysisPdfRecord>> _loadHistory() {
    return AnalysisPdfService.getHistory(studentId: widget.student.id);
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _loadHistory();
    });
    await _historyFuture;
  }

  Future<void> _shareRecord(AnalysisPdfRecord record) async {
    try {
      await AnalysisPdfService.shareHistoryRecord(record);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open saved PDF: $error')),
      );
    }
  }

  Future<void> _deleteRecord(AnalysisPdfRecord record) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete PDF?'),
        content: Text('Remove ${record.title} from PDF history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await AnalysisPdfService.deleteHistoryRecord(record);
    if (!mounted) return;

    await _refreshHistory();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF removed from history.')));
  }

  String _prettyFileName(String fileName) {
    final base = fileName.toLowerCase().endsWith('.pdf')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    return base.replaceAll('_', ' ');
  }

  String _analysisTypeLabel(String analysisType) {
    switch (analysisType.trim().toLowerCase()) {
      case 'semester':
        return 'Semester analysis';
      case 'subject':
        return 'Subject analysis';
      default:
        return 'Analysis';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis PDF History')),
      body: FutureBuilder<List<AnalysisPdfRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          final history = snapshot.data ?? const <AnalysisPdfRecord>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 64,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No PDFs saved yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Export from semester-wise or subject-wise analysis first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = history[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? Colors.white.withAlpha(8)
                        : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFEF4444),
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _prettyFileName(record.fileName),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: record.analysisType == 'semester'
                                        ? const Color(0xFF6C63FF).withAlpha(18)
                                        : const Color(0xFF00C9A7).withAlpha(18),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _analysisTypeLabel(record.analysisType),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: record.analysisType == 'semester'
                                          ? const Color(0xFF6C63FF)
                                          : const Color(0xFF00C9A7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(record.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _shareRecord(record),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Share'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _deleteRecord(record),
                              icon: const Icon(Icons.delete_rounded, size: 18),
                              label: const Text('Delete'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AnalysisPdfRecord {
  final String id;
  final String title;
  final String analysisType;
  final String studentId;
  final String studentName;
  final String fileName;
  final String? pdfPath;
  final String? pdfBase64;
  final DateTime createdAt;

  AnalysisPdfRecord({
    required this.id,
    required this.title,
    required this.analysisType,
    required this.studentId,
    required this.studentName,
    required this.fileName,
    this.pdfPath,
    this.pdfBase64,
    required this.createdAt,
  });

  AnalysisPdfRecord copyWith({
    String? id,
    String? title,
    String? analysisType,
    String? studentId,
    String? studentName,
    String? fileName,
    String? pdfPath,
    String? pdfBase64,
    DateTime? createdAt,
  }) {
    return AnalysisPdfRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      analysisType: analysisType ?? this.analysisType,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      fileName: fileName ?? this.fileName,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfBase64: pdfBase64 ?? this.pdfBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'analysisType': analysisType,
      'studentId': studentId,
      'studentName': studentName,
      'fileName': fileName,
      'pdfPath': pdfPath,
      'pdfBase64': pdfBase64,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AnalysisPdfRecord.fromJson(Map<String, dynamic> json) {
    return AnalysisPdfRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      analysisType: json['analysisType'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      fileName: json['fileName'] as String,
      pdfPath: json['pdfPath'] as String?,
      pdfBase64: json['pdfBase64'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

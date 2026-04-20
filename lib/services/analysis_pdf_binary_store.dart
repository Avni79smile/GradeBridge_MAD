import 'dart:typed_data';

import 'analysis_pdf_binary_store_stub.dart'
    if (dart.library.io) 'analysis_pdf_binary_store_io.dart';

class AnalysisPdfBinaryStoreSaveResult {
  final String? filePath;
  final String? inlineBase64;

  const AnalysisPdfBinaryStoreSaveResult({this.filePath, this.inlineBase64});
}

abstract class AnalysisPdfBinaryStore {
  Future<AnalysisPdfBinaryStoreSaveResult> save({
    required String fileName,
    required Uint8List pdfBytes,
  });

  Future<Uint8List?> load({String? filePath, String? inlineBase64});

  Future<bool> exists({String? filePath, String? inlineBase64});

  Future<void> delete({String? filePath});
}

AnalysisPdfBinaryStore createAnalysisPdfBinaryStore() =>
    createPlatformAnalysisPdfBinaryStore();

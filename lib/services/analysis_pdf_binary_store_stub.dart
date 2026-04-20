import 'dart:convert';
import 'dart:typed_data';

import 'analysis_pdf_binary_store.dart';

class _StubAnalysisPdfBinaryStore implements AnalysisPdfBinaryStore {
  @override
  Future<void> delete({String? filePath}) async {}

  @override
  Future<bool> exists({String? filePath, String? inlineBase64}) async {
    return inlineBase64 != null && inlineBase64.isNotEmpty;
  }

  @override
  Future<Uint8List?> load({String? filePath, String? inlineBase64}) async {
    if (inlineBase64 == null || inlineBase64.isEmpty) {
      return null;
    }
    return base64Decode(inlineBase64);
  }

  @override
  Future<AnalysisPdfBinaryStoreSaveResult> save({
    required String fileName,
    required Uint8List pdfBytes,
  }) async {
    return AnalysisPdfBinaryStoreSaveResult(
      inlineBase64: base64Encode(pdfBytes),
    );
  }
}

AnalysisPdfBinaryStore createPlatformAnalysisPdfBinaryStore() =>
    _StubAnalysisPdfBinaryStore();

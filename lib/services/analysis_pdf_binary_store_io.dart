import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'analysis_pdf_binary_store.dart';

class _IoAnalysisPdfBinaryStore implements AnalysisPdfBinaryStore {
  Future<Directory> _historyDirectory() async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      path.join(baseDirectory.path, 'analysis_pdf_history'),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  @override
  Future<void> delete({String? filePath}) async {
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists({String? filePath, String? inlineBase64}) async {
    if (filePath == null || filePath.isEmpty) {
      return inlineBase64 != null && inlineBase64.isNotEmpty;
    }

    return File(filePath).exists();
  }

  @override
  Future<Uint8List?> load({String? filePath, String? inlineBase64}) async {
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        return file.readAsBytes();
      }
    }

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
    final directory = await _historyDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);

    return AnalysisPdfBinaryStoreSaveResult(filePath: file.path);
  }
}

AnalysisPdfBinaryStore createPlatformAnalysisPdfBinaryStore() =>
    _IoAnalysisPdfBinaryStore();

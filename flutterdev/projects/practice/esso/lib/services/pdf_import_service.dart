
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfImportService {
  Future<File?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.single.path;

    if (path == null || path.isEmpty) {
      throw Exception('The selected PDF file could not be accessed.');
    }

    final file = File(path);

    if (!await file.exists()) {
      throw Exception('The selected PDF file no longer exists.');
    }

    return file;
  }

  Future<int> getPageCount(File file) async {
    final document = await PdfDocument.openFile(file.path);

    try {
      return document.pages.length;
    } finally {
      await document.dispose();
    }
  }
}

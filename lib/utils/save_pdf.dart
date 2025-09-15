import 'dart:typed_data';

// Conditional import: pick the web or io implementation depending on the platform.
import 'save_pdf_io.dart' if (dart.library.html) 'save_pdf_web.dart' as impl;

/// Save a PDF represented by [bytes] with suggested [fileName].
///
/// Returns a Map with keys:
/// - 'directory': human-friendly directory label (eg. 'Downloads' or 'Documents')
/// - 'path': full path or filename where the file was written (on web this is the filename)
Future<Map<String, String>> savePdf(Uint8List bytes, String fileName) async {
  return await impl.savePdf(bytes, fileName);
}

// This file intentionally uses `dart:html` for Flutter Web builds only.
// The file is conditionally imported only when `dart.library.html` is available.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:typed_data';
import 'dart:html' as html;

Future<Map<String, String>> savePdf(Uint8List bytes, String fileName) async {
  // Create a blob URL and trigger a download in the browser
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  // On web there's no directory concept; return filename as path
  return {'directory': 'Browser Download', 'path': fileName};
}

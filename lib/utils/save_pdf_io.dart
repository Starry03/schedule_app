import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<Map<String, String>> savePdf(Uint8List bytes, String fileName) async {
  Directory? directory;
  String directoryName = '';

  if (Platform.isAndroid) {
    try {
      directory = await getExternalStorageDirectory();
      directoryName = 'Storage Android';
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
      directoryName = 'App Documents';
    }
  } else {
    try {
      directory = await getDownloadsDirectory();
      if (directory != null && await directory.exists()) {
        directoryName = 'Downloads';
      } else {
        throw Exception('Downloads directory not accessible');
      }
    } catch (_) {
      try {
        final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        if (homeDir != null) {
          directory = Directory('$homeDir/Documents');
          if (await directory.exists()) {
            directoryName = 'Documents';
          } else {
            throw Exception('Documents directory not accessible');
          }
        } else {
          throw Exception('Home directory not found');
        }
      } catch (_) {
        directory = await getApplicationDocumentsDirectory();
        directoryName = 'App Documents';
      }
    }
  }

  if (directory == null) {
    throw Exception('No writable directory available');
  }

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  return {'directory': directoryName, 'path': file.path};
}

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<File> saveImageToInternalStorage(File imageFile) async {
    // Tomar directorio interno
    final directory = await getApplicationDocumentsDirectory();

    // Crear carpeta "JournalImages"
    final folderPath = '${directory.path}/JournalImages';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    // Crear nombre YYYY-MM-DD
    final date = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final extension = imageFile.path.split('.').last;
    final newPath = '$folderPath/$date.$extension';

    // Copiar archivo a memoria interna
    return imageFile.copy(newPath);
  }

  /// Get image file from date (for loading existing journal entries)
  static Future<String?> getImageFromDate(String date) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = '${directory.path}/JournalImages';
      final folder = Directory(folderPath);

      if (!await folder.exists()) {
        return null;
      }

      // List all files in the folder
      final files = folder.listSync();

      // Parse the date to find matching files
      final targetDate = DateTime.tryParse(date);
      if (targetDate == null) return null;

      final dateString = DateFormat('yyyy-MM-dd').format(targetDate);

      // Find file that starts with the date
      for (final file in files) {
        if (file is File && file.path.contains(dateString)) {
          return file.path;
        }
      }

      return null;
    } catch (e) {
      print('Error getting image from date: $e');
      return null;
    }
  }
}

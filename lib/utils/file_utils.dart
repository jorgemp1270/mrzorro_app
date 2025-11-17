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
}

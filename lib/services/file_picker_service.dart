import 'dart:io';
import 'package:file_picker/file_picker.dart';

abstract class FilePickerService {
  Future<File?> pickFile();
}

class RealFilePickerService implements FilePickerService {
  @override
  Future<File?> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}


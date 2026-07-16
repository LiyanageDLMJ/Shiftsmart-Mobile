import 'dart:io';
import 'package:image_picker/image_picker.dart';

abstract class ImagePickerService {
  Future<File?> pickImage();
}

class RealImagePickerService implements ImagePickerService{
  @override
  Future<File?> pickImage() async{
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 768,
      maxWidth: 1024,
      imageQuality: 70,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }
}
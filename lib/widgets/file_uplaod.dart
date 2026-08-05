import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileUpload extends StatefulWidget {
  final Function(File?) onFileSelected;

  const FileUpload({super.key, required this.onFileSelected});

  @override
  State<FileUpload> createState() => _FileUploadState();
}

class _FileUploadState extends State<FileUpload> {
  File? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
      widget.onFileSelected(_selectedFile);
    }
  }

  bool _isImage(String path) {
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Upload files",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Supported: PDF, JPG, PNG",
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
            child: _selectedFile == null
                ? _buildPlaceholder()
                : _isImage(_selectedFile!.path)
                    ? _buildImagePreview()
                    : _buildFilePreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: const Icon(Icons.cloud_upload_outlined,
              color: Colors.black, size: 28),
        ),
        const SizedBox(height: 16),
        const Text("Choose a file or drag & drop it here",
            style: TextStyle(color: Colors.black, fontSize: 16)),
        const SizedBox(height: 8),
        const Text("JPEG, PNG, or PDF",
            style: TextStyle(color: Colors.black, fontSize: 12)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Colors.black.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Text("Browse File",
              style: TextStyle(color: Colors.black, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_selectedFile!, fit: BoxFit.cover),
          ),
        ),
        _buildRemoveButton()
      ],
    );
  }

  Widget _buildFilePreview() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _selectedFile!.path.split('/').last,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _buildRemoveButton()
      ],
    );
  }

  Widget _buildRemoveButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFile = null;
          });
          widget.onFileSelected(null);
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.close, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MediaViewer extends StatelessWidget {
  final String url;

  const MediaViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      appBar: AppBar(
        title: const Text("Job Media"),
        backgroundColor: const Color(0xFF1C2230),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhotoView(
              imageProvider: NetworkImage(url),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }
}

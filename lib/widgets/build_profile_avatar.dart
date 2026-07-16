import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';

class ProfileAvatar extends StatefulWidget {
  final bool editable;
  final File? initialImage;
  final Function(File)? onImageSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final bool useProviderImage;
  final IconData placeholderIcon;

  const ProfileAvatar({
    super.key,
    this.editable = true,
    this.initialImage,
    this.onImageSelected,
    this.onTap,
    this.onEditTap,
    this.useProviderImage = true,
    this.placeholderIcon = Icons.account_circle,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _selectedImageFile = widget.initialImage;
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
      });

      if (widget.onImageSelected != null) {
        widget.onImageSelected!(_selectedImageFile!);
      }
    }
  }

  Future<void> _showImageSourceOptions(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E2433),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take photo',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.white),
                title:
                    const Text('Cancel', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _pickImageFromSource(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = widget.useProviderImage
        ? Provider.of<UserProvider>(context).userProfile
        : const <String, dynamic>{};
    final imageValue =
        userProfile["profilePicture"] ?? userProfile["ProfilePicture"];
    final imageProvider = _imageProvider(imageValue);

    final avatar = Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      child: ClipOval(
        child: _selectedImageFile != null
            ? Image.file(
                _selectedImageFile!,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              )
            : imageProvider != null
                ? Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  )
                : Icon(widget.placeholderIcon, size: 100, color: Colors.white),
      ),
    );

    return GestureDetector(
      onTap: widget.onTap ??
          (widget.editable ? () => _showImageSourceOptions(context) : null),
      child: Stack(
        children: [
          avatar,
          if (widget.editable)
            Positioned(
              right: 4,
              bottom: 4,
              child: GestureDetector(
                onTap:
                    widget.onEditTap ?? () => _showImageSourceOptions(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F36), // Dark premium color
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _imageProvider(dynamic value) {
    final image = value?.toString().trim() ?? '';
    if (image.isEmpty) return null;

    if (image.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(image.split(',').last));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(image);
  }
}

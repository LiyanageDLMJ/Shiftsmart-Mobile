import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:shiftsmart/models/empcert_model.dart';
import 'package:shiftsmart/services/onboarding_service.dart';

class EmployeeDocumentDetail extends StatefulWidget {
  final EmployeeCertificate document;

  const EmployeeDocumentDetail({super.key, required this.document});

  @override
  State<EmployeeDocumentDetail> createState() => _EmployeeDocumentDetailState();
}

class _EmployeeDocumentDetailState extends State<EmployeeDocumentDetail> {
  File? _selectedFile;
  String? _selectedFileName;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = path.basename(_selectedFile!.path);
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to update.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final int documentId = widget.document.documentId ?? 0;
    final String documentType = widget.document.documentType;

    final String? error = await OnboardingService().resubmitDocument(
      documentId: documentId,
      file: _selectedFile!,
      documentType: documentType,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document update submitted successfully.')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  Future<void> _openDocument() async {
    final url = widget.document.documentUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is missing.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open document URL.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
    }
  }

  String get _formattedUploadedAt {
    try {
      final date = DateTime.parse(widget.document.uploadedAt);
      return DateFormat.yMMMMd().format(date);
    } catch (_) {
      return widget.document.uploadedAt;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return Colors.greenAccent;
      case 'pending':
        return Colors.orangeAccent;
      case 'rejected':
      case 'declined':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
        backgroundColor: const Color(0xFF1C2230),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1C2230),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDetailCard(),
              const SizedBox(height: 24),
              if (widget.document.status.toLowerCase() != 'approved' && 
                  widget.document.status.toLowerCase() != 'verified')
                _buildActionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2A3240), const Color(0xFF1C2230)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: Color(0xFF3498DB),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.document.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          _buildInfoRow('Type', widget.document.documentType),
          _buildInfoRow('Status', widget.document.status, 
              valueColor: _getStatusColor(widget.document.status)),
          _buildInfoRow('Uploaded', _formattedUploadedAt),
          if (widget.document.remarks != null && widget.document.remarks!.isNotEmpty)
            _buildInfoRow('Remarks', widget.document.remarks!),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('VIEW DOCUMENT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _openDocument,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUBMIT DOCUMENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFileName ?? 'Select new file...',
                      style: TextStyle(
                        color: _selectedFileName != null ? Colors.white : Colors.white38,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedFileName != null)
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.white10,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'SUBMIT UPDATE',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label',
              style: const TextStyle(
                color: Colors.white38, 
                fontSize: 13,
                fontWeight: FontWeight.w500
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white70, 
                fontSize: 14,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }
}

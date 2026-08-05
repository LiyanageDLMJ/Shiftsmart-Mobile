import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/models/empcert_model.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/emp_slidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:path/path.dart' as path;
import 'media_viewer.dart';

class Employeecert extends StatefulWidget {
  const Employeecert({super.key});

  @override
  State<Employeecert> createState() => _EmployeecertState();
}

class _EmployeecertState extends State<Employeecert> {
  List<EmployeeCertificate> _certificates = [];
  bool _isLoading = true;
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _employeeId = prefs.getInt('employeeId') ?? prefs.getInt('userId');

      if (_employeeId != null) {
        final docs =
            await EmployeeService().fetchEmployeeDocuments(_employeeId!);
        setState(() {
          _certificates = docs;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint(" No Employee ID found in SharedPreferences");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading docs: $e")),
        );
      }
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

  Future<String> _downloadableDocumentUrl(EmployeeCertificate doc) async {
    final documentId = doc.documentId ?? 0;
    if (documentId > 0) {
      final signedUrl = await EmployeeService().fetchDocumentDownloadUrl(
        documentId,
      );
      if (signedUrl != null && signedUrl.isNotEmpty) return signedUrl;
    }
    return doc.documentUrl;
  }

  Future<void> _viewDocument(EmployeeCertificate doc) async {
    final url = await _downloadableDocumentUrl(doc);
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document URL is missing")),
      );
      return;
    }
    if (!mounted) return;
    await _openInAppViewer(doc, url);
  }

  String _documentTitle(EmployeeCertificate doc) {
    final type = doc.documentType.trim();
    if (type.isNotEmpty) return type;

    final name = doc.fileName.trim();
    return name.isNotEmpty ? name : 'Document';
  }

  String _documentGroupKey(EmployeeCertificate doc) {
    return _documentTitle(doc).trim().toLowerCase();
  }

  List<List<EmployeeCertificate>> _groupedCertificates() {
    final groups = <String, List<EmployeeCertificate>>{};

    for (final doc in _certificates) {
      groups.putIfAbsent(_documentGroupKey(doc), () => []).add(doc);
    }

    return groups.values.toList();
  }

  String _groupStatus(List<EmployeeCertificate> docs) {
    if (docs.any((doc) {
      final status = doc.status.toLowerCase();
      return status == 'rejected' || status == 'declined';
    })) {
      return 'Rejected';
    }
    if (docs.any((doc) => doc.status.toLowerCase() == 'pending')) {
      return 'Pending';
    }
    return docs.first.status;
  }

  bool _isImageUrl(String url) {
    final cleanUrl = url.split('?').first.toLowerCase();
    return cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.webp');
  }

  bool _isPdfUrl(String url) {
    return url.split('?').first.toLowerCase().endsWith('.pdf');
  }

  Future<void> _openInAppViewer(EmployeeCertificate doc, String url) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewer(
          url: url,
          title: _documentTitle(doc),
          isPdf: _isPdfUrl(url),
        ),
      ),
    );
  }

  Future<Uint8List> _loadDocumentBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Could not load document (${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  Future<void> _viewDocumentGroup(List<EmployeeCertificate> docs) async {
    final availableDocs =
        docs.where((doc) => doc.documentUrl.trim().isNotEmpty).toList();

    if (availableDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document URL is missing")),
      );
      return;
    }

    if (availableDocs.length == 1 &&
        !_isImageUrl(availableDocs.first.documentUrl)) {
      await _viewDocument(availableDocs.first);
      return;
    }

    final controller = PageController();
    var currentIndex = 0;
    final urlFutures = <int, Future<String>>{};
    final byteFutures = <String, Future<Uint8List>>{};

    Future<String> urlFor(EmployeeCertificate doc) {
      final key = doc.documentId ?? availableDocs.indexOf(doc);
      return urlFutures.putIfAbsent(key, () => _downloadableDocumentUrl(doc));
    }

    Future<Uint8List> bytesFor(String url) {
      return byteFutures.putIfAbsent(url, () => _loadDocumentBytes(url));
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1C2230),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _documentTitle(availableDocs.first).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon:
                                const Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: availableDocs.length,
                        onPageChanged: (index) {
                          setDialogState(() => currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final doc = availableDocs[index];

                          return FutureBuilder<String>(
                            future: urlFor(doc),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF3498DB),
                                  ),
                                );
                              }

                              final url = snapshot.data ?? doc.documentUrl;
                              if (_isImageUrl(url)) {
                                return FutureBuilder<Uint8List>(
                                  future: bytesFor(url),
                                  builder: (context, imageSnapshot) {
                                    if (imageSnapshot.connectionState !=
                                        ConnectionState.done) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF3498DB),
                                        ),
                                      );
                                    }

                                    if (imageSnapshot.hasError ||
                                        !imageSnapshot.hasData) {
                                      return _documentOpenFallback(
                                        doc,
                                        onRetry: () {
                                          final key = doc.documentId ?? index;
                                          urlFutures.remove(key);
                                          byteFutures.clear();
                                          setDialogState(() {});
                                        },
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: InteractiveViewer(
                                        minScale: 0.8,
                                        maxScale: 4,
                                        child: Image.memory(
                                          imageSnapshot.data!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              return _documentOpenFallback(doc, url: url);
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(availableDocs.length, (index) {
                          return Container(
                            width: index == currentIndex ? 18 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? const Color(0xFF3498DB)
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Widget _documentOpenFallback(
    EmployeeCertificate doc, {
    String? url,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file,
              color: Color(0xFF3498DB), size: 54),
          const SizedBox(height: 12),
          Text(
            path.basename((url ?? doc.documentUrl).split('?').first),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final documentUrl = url ?? await _downloadableDocumentUrl(doc);
              if (!mounted) return;
              await _openInAppViewer(doc, documentUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              foregroundColor: Colors.white,
            ),
            child: const Text("OPEN DOCUMENT"),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
              child: const Text("Retry preview"),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteDocument(EmployeeCertificate doc) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2230),
        title: const Text("Delete Document",
            style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete ${doc.fileName}?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && doc.documentId != null) {
      setState(() => _isLoading = true);
      final bool success =
          await EmployeeService().deleteCertificate(doc.documentId!);
      if (success) {
        _loadDocuments();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete document")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EmpSidenav(currentScreen: 'EmployeeCert'),
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(showBackButton: false),
      body: Stack(children: [
        const Background(),
        Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "MY DOCUMENTS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Manage your onboarding documents",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _buildDocList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ])
      ]),
    );
  }

  Widget _buildDocList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_certificates.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 30),
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: const [
            Icon(Icons.folder_off_outlined, size: 40, color: Colors.white38),
            SizedBox(height: 10),
            Text("No documents found.",
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Column(
      children: _groupedCertificates().map((docs) {
        final doc = docs.first;
        final title = _documentTitle(doc);
        final status = _groupStatus(docs);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A3240), Color(0xFF1C2230)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.article_rounded,
                      color: Color(0xFF3498DB),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                        if (docs.length > 1) ...[
                          const SizedBox(height: 3),
                          Text(
                            "${docs.length} files",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _viewDocumentGroup(docs),
                    child: const Text("VIEW",
                        style: TextStyle(
                            color: Color(0xFF3498DB),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (doc.documentType.toLowerCase() == 'general')
                    TextButton(
                      onPressed: () => _deleteDocument(doc),
                      child: const Text("DELETE",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

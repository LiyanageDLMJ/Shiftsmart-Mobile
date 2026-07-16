import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/services/certificate_service.dart';
import 'package:shiftsmart/services/file_picker_service.dart';
import 'package:shiftsmart/widgets/custom_date_picker.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';

class Employeecertcreate extends StatefulWidget {
  final FilePickerService filePickerService;
  const Employeecertcreate({
    super.key,
    required this.filePickerService,
  });

  @override
  State<Employeecertcreate> createState() => _EmployeecertcreateState();
}

class _EmployeecertcreateState extends State<Employeecertcreate> {
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _dateIssuedController = TextEditingController();

  String? selectedFileType;
  File? selectedFile;
  String? fileName;

  int? employeeId;
  int? uploadedBy;

  @override
  void initState() {
    super.initState();

    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('employeeId');

    setState(() {
      employeeId = id;
      uploadedBy = id;
    });

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error: employeeId not set. Please login again.")),
      );
    }
  }

  Future<void> _pickFile() async {
    final file = await widget.filePickerService.pickFile();
    if (file != null) {
      setState(() {
        selectedFile = file;
        fileName = path.basename(file.path);
      });
    }
  }

  Future<void> _uploadCertificate() async {
    if (selectedFile == null ||
        selectedFileType == null ||
        _expiryDateController.text.isEmpty ||
        _dateIssuedController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill in all fields and select a file")),
      );
      return;
    }

    final errorMessage = await CertificateService().uploadCertificate(
      file: selectedFile!,
      employeeId: employeeId!,
      certificateType: selectedFileType!,
      dateIssued: _dateIssuedController.text,
      expiryDate: _expiryDateController.text,
    );

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload successful")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(48, 92, 92, 92),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(16),
            constraints:
                BoxConstraints(maxHeight: screenHeight * 0.9, maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  _headerSection(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Select File Type",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: selectedFileType,
                            dropdownColor: Colors.black87,
                            decoration: _dropdownDecoration(),
                            items: ['CV', 'Contract'].map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => selectedFileType = value),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: _elevatedStyle(),
                            icon: const Icon(Icons.upload_file,
                                color: Colors.white),
                            label: const Text("Upload File",
                                style: TextStyle(color: Colors.white)),
                            onPressed: _pickFile,
                          ),
                          if (fileName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text("Selected File: $fileName",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _dateIssuedController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration("Date Issued"),
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: datePickerThemeBuilder);
                              _dateIssuedController.text =
                                  picked.toString().split('T').first;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _expiryDateController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration("Expiry Date"),
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                  builder: datePickerThemeBuilder);
                              _expiryDateController.text =
                                  picked.toString().split('T').first;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GradientButton(
                                  text: "Cancel",
                                  onPressed: () => Navigator.pop(context),
                                  isCancel: true),
                              GradientButton(
                                  text: "Add", onPressed: _uploadCertificate),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      );

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.white12,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      );

  ButtonStyle _elevatedStyle() => ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );

  Widget _headerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Add Certificates",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Image.asset(
            'assets/Diploma.png',
            color: const Color(0xFF3498DB),
            width: 35,
            height: 35,
          ),
        ],
      ),
    );
  }
}

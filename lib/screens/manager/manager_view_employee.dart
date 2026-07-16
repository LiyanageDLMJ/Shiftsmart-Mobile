import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/models/empcert_model.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/services/certificate_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/gradienthorizontal.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:url_launcher/url_launcher.dart';

class Managerviewemployee extends StatefulWidget {
  final Employee employee;

  const Managerviewemployee({super.key, required this.employee});

  @override
  State<Managerviewemployee> createState() => _ManagerviewemployeeState();
}

class _ManagerviewemployeeState extends State<Managerviewemployee> {
  bool _isInitialized = false;
  Map<String, dynamic>? userProfile;

  List<EmployeeCertificate> _certificates = [];
  bool _isLoadingCertificates = true;
  final CertificateService _certificateService = CertificateService();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        final profile =
            Provider.of<UserProvider>(context, listen: false).userProfile;
        setState(() {
          userProfile = profile;
          _isInitialized = true;
        });
      }
    });

    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    // final employeeId = widget.employee.employeeId;
    try {
      final certificates = await _certificateService.fetchCertificates(widget.employee.employeeId);

      setState(() {
        _certificates = certificates;
        _isLoadingCertificates = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoadingCertificates = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(
        showBackButton: true,
      ),
      drawer: const Sidenav(),
      body: Stack(
        children: [
          const Background(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Gradienthorizontal(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        const Text(
                          "Personal Details",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Table(
                                  columnWidths: const {
                                    0: IntrinsicColumnWidth(),
                                    1: FlexColumnWidth(),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    _buildTableRow("First Name",
                                        widget.employee.firstName),
                                    _buildTableRow("Middle Name",
                                        widget.employee.middleName ?? "-"),
                                    _buildTableRow("Last Name",
                                        widget.employee.lastName ?? "-"),
                                    _buildTableRow("Gender",
                                        widget.employee.gender ?? "-"),
                                    _buildTableRow("Mobile Number",
                                        widget.employee.mobileNumber ?? "-"),
                                    _buildTableRow(
                                        "Email", widget.employee.email ?? "-"),
                                    _buildTableRow("Street",
                                        widget.employee.street ?? "-"),
                                    _buildTableRow(
                                        "City", widget.employee.city ?? "-"),
                                    _buildTableRow(
                                        "State", widget.employee.state ?? "-"),
                                    _buildTableRow("Postal Code",
                                        widget.employee.postalCode ?? "-"),
                                    _buildTableRow("Country",
                                        widget.employee.country ?? "-"),
                                    _buildTableRow(
                                      "Date of Birth",
                                      widget.employee.dateOfBirth != null
                                          ? widget.employee.dateOfBirth!
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0]
                                          : "-",
                                    ),
                                    _buildTableRow(
                                        "Employment Status",
                                        widget.employee.employmentStatus ??
                                            "-"),
                                    _buildTableRow("Job Role",
                                        widget.employee.jobRole ?? "-"),
                                    _buildTableRow("User Role",
                                        widget.employee.userRole ?? "-"),
                                    _buildTableRow("Bank Account Name",
                                        widget.employee.bankAccountName ?? "-"),
                                    _buildTableRow(
                                        "Bank Account Number",
                                        widget.employee.bankAccountNumber ??
                                            "-"),
                                    _buildTableRow("Bank BSB",
                                        widget.employee.bankBSB ?? "-"),
                                    _buildTableRow("Bank Name",
                                        widget.employee.bankName ?? "-"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (widget.employee.nextOfKins.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Next of Kin",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          // const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const Text(
                                  //   "Next of Kin",
                                  //   style: TextStyle(
                                  //       fontSize: 18,
                                  //       fontWeight: FontWeight.bold,
                                  //       color: Colors.white),
                                  // ),
                                  const SizedBox(height: 10),
                                  Table(
                                    columnWidths: const {
                                      0: IntrinsicColumnWidth(),
                                      1: FlexColumnWidth(),
                                    },
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      for (var kin
                                          in widget.employee.nextOfKins) ...[
                                        _buildTableRow("Name", kin.fullName),
                                        _buildTableRow(
                                            "Relationship", kin.relationship),
                                        TableRow(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: Text(
                                                "Mobile Number:",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: GestureDetector(
                                                onTap: () => _makePhoneCall(
                                                    kin.mobileNumber),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    const Icon(Icons.phone,
                                                        color: Colors.white,
                                                        size: 18),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      kin.mobileNumber,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        _buildTableRow("Email", kin.email),
                                        _buildTableRow("Address", kin.address),
                                        const TableRow(children: [
                                          SizedBox(height: 16),
                                          SizedBox()
                                        ]),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Certificates Section
                        if (_isLoadingCertificates)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                CircularProgressIndicator(color: Colors.blue),
                          )
                        else if (_certificates.isNotEmpty) ...[
                          const Text(
                            "Certificates",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                          // const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const Text(
                                  //   "Certificates",
                                  //   style: TextStyle(
                                  //       fontSize: 18,
                                  //       fontWeight: FontWeight.bold,
                                  //       color: Colors.white),
                                  // ),
                                  const SizedBox(height: 10),
                                  if (_isLoadingCertificates)
                                    const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.blue))
                                  else if (_certificates.isNotEmpty)
                                    ..._certificates.map((cert) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(cert.fileName,
                                                    style: const TextStyle(
                                                        color: Colors.white)),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  final url = cert.documentUrl;
                                                  final uri = Uri.parse(url);
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(
                                                      uri,
                                                      mode: LaunchMode.externalApplication,
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Cannot open certificate')),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  width: 100,
                                                  height: 45,
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Color(0xFF34C8E8),
                                                        Color(0xFF4E4AF2)
                                                      ],
                                                      begin:
                                                          Alignment.centerLeft,
                                                      end:
                                                          Alignment.centerRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text("View",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      SizedBox(width: 10),
                                                      Icon(
                                                          Icons
                                                              .picture_as_pdf_outlined,
                                                          color: Colors.white,
                                                          size: 20),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                  else
                                    const Text("No certificates found.",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              "No certificates found.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profilePicture = widget.employee.profilePicture;

    ImageProvider? imageProvider;
    if (profilePicture != null && profilePicture.startsWith('data:image')) {
      try {
        final base64Str = profilePicture.split(',').last;
        final bytes = base64Decode(base64Str);
        imageProvider = MemoryImage(bytes);
      } catch (_) {
        imageProvider = null;
      }
    } else if (profilePicture != null && profilePicture.isNotEmpty) {
      imageProvider = NetworkImage(profilePicture);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                ),
                child: ClipOval(
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 80,
                              color: Colors.white70,
                            );
                          },
                        )
                      : const Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Colors.white70,
                        ),
                ),
              ),
              // Positioned(
              //   right: 0,
              //   bottom: 0,
              //   child: Container(
              //     padding: const EdgeInsets.all(6),
              //     decoration: const BoxDecoration(
              //       color: Colors.grey,
              //       shape: BoxShape.circle,
              //     ),
              // child: const Icon(
              //   Icons.edit,
              //   color: Colors.white,
              //   size: 20,
              // ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "$label:",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

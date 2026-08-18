import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shiftsmart/models/company.dart';
import 'package:shiftsmart/services/company_service.dart';
import 'package:shiftsmart/utils/country_dial_codes.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/utils/google_maps_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/country_code_phone_field.dart';
import 'package:shiftsmart/widgets/manager_screen_style.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/success_dialog.dart'; //  Import Success Dialog
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

class Managercreatecom extends StatefulWidget {
  final Company? company;

  const Managercreatecom({super.key, this.company});

  @override
  State<Managercreatecom> createState() => _ManagercreatecomState();
}

class _ManagercreatecomState extends State<Managercreatecom> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _personController = TextEditingController();

  // Address Search Variables
  String tokenForSession = const Uuid().v4();
  List<Map<String, String>> _suggestions = [];
  bool _isSaving = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    if (widget.company != null) {
      _nameController.text = widget.company!.name;
      _phoneController.text = widget.company!.phoneNumber.toString();
      _addController.text = widget.company!.address;
      _personController.text = widget.company!.ContactPerson;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addController.dispose();
    _personController.dispose();
    super.dispose();
  }

  Future<List<Map<String, String>>> makeSuggestion(String input) async {
    final key = GoogleMapsHelper.apiKey;
    final endpoint = dotenv.env['GOOGLE_PLACES_AUTOCOMPLETE_URL'] ?? '';
    if (endpoint.isEmpty) return [];
    final url = "$endpoint?input=$input&key=$key&sessiontoken=$tokenForSession";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: GoogleMapsHelper.platformHeaders,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final predictions = json['predictions'] as List;
        return predictions.map<Map<String, String>>((e) {
          final structured = e['structured_formatting'] ?? {};
          return {
            "description": e['description'] ?? '',
            "place_id": e['place_id'] ?? '',
            "main_text": structured['main_text'] ?? e['description'] ?? '',
            "secondary_text": structured['secondary_text'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Address fetch error: $e");
    }
    return [];
  }

  // --- 2. Save Logic ---
  Future<void> _saveCompany() async {
    // Basic Validation
    final name = _nameController.text.trim();
    final contactPerson = _personController.text.trim();
    final contactNumber = _phoneController.text.trim();
    final address = _addController.text.trim();

    if (name.isEmpty ||
        contactPerson.isEmpty ||
        contactNumber.isEmpty ||
        address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    final textOnlyRegex = RegExp(r'^[A-Za-z ]+$');

    if (!textOnlyRegex.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Company name can contain letters only")),
      );
      return;
    }

    if (!textOnlyRegex.hasMatch(contactPerson)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Contact person can contain letters only")),
      );
      return;
    }

    final phoneError = validateInternationalPhoneNumber(
      contactNumber,
      requiredMessage: 'Contact Number is required.',
      invalidMessage: 'Please enter a valid mobile number.',
    );
    if (phoneError != null) {
      setState(() => _phoneError = phoneError);
      return;
    }

    setState(() => _phoneError = null);

    setState(() => _isSaving = true);

    final Map<String, dynamic> companyData = {
      "Name": name,
      "ContactNumber": contactNumber,
      "Address": address,
      "ContactPerson": contactPerson,
    };

    if (widget.company != null) {
      companyData["CompanyId"] = widget.company!.id;
    }

    bool success = false;

    try {
      if (widget.company != null) {
        success = await CompanyService()
            .updateCompany(widget.company!.id, companyData);
      } else {
        success = await CompanyService().addCompany(companyData);
      }

      setState(() => _isSaving = false);

      if (mounted) {
        if (success) {
          // --- Show Success Dialog ---
          SuccessDialog.show(
            context,
            title: widget.company != null
                ? "Update Successful"
                : "Creation Successful",
            message: widget.company != null
                ? "Company details have been updated."
                : "New company has been created successfully.",
            buttonText: "OK",
            onPressed: () {
              Navigator.pop(context, true); // Return to list screen with 'true'
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save company")),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.company != null;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      drawer: const Sidenav(),
      resizeToAvoidBottomInset: true,
      backgroundColor: ManagerScreenStyle.pageBg,
      appBar: const Uppernavbar(
        showBackButton: true,
      ),
      body: Stack(children: [
        const Positioned.fill(child: Background()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ManagerFormShell(
              title: isEditMode ? "UPDATE COMPANY" : "CREATE COMPANY",
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  0,
                  20,
                  0,
                  keyboardInset + 120,
                ),
                children: [
                  ManagerSectionPanel(
                    title: 'Company Details',
                    subtitle:
                        'Add contact information and the company address.',
                    child: Column(
                      children: [
                        _buildTextField(
                          "Name",
                          _nameController,
                          required: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z ]')),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildTextField(
                          "Contact Person",
                          _personController,
                          required: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z ]')),
                          ],
                        ),
                        const SizedBox(height: 18),
                        CountryCodePhoneField(
                          label: 'Contact Number',
                          controller: _phoneController,
                          errorText: _phoneError,
                          validator: (value) =>
                              validateInternationalPhoneNumber(
                            value,
                            requiredMessage: 'Contact Number is required.',
                            invalidMessage:
                                'Please enter a valid mobile number.',
                          ),
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildAddressField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ManagerActionButton(
                          text: "Cancel",
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context),
                          secondary: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ManagerActionButton(
                          text: _isSaving
                              ? (isEditMode ? "Updating..." : "Creating...")
                              : (isEditMode
                                  ? "Update Company"
                                  : "Save Company"),
                          icon: Icons.check_circle_rounded,
                          onPressed: _isSaving ? () {} : _saveCompany,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }

  // Generic Text Field
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManagerFieldLabel(label, required: required),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: managerFieldDecoration(),
        ),
      ],
    );
  }

  // Address Field with Suggestions
  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ManagerFieldLabel("Address", required: true),
        const SizedBox(height: 8),
        TextField(
          controller: _addController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (value) async {
            if (value.isNotEmpty) {
              final results = await makeSuggestion(value);
              setState(() {
                _suggestions = results;
              });
            } else {
              setState(() {
                _suggestions = [];
              });
            }
          },
          decoration: managerFieldDecoration(
            suffixIcon: _suggestions.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () => setState(() => _suggestions = []),
                  )
                : null,
          ),
        ),

        // Suggestion List Dropdown
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      final mainText = suggestion['main_text'] ?? '';
                      final secondaryText = suggestion['secondary_text'] ?? '';
                      final fullDescription = suggestion['description'] ?? '';

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 20,
                            ),
                            minLeadingWidth: 10,
                            dense: true,
                            title: RichText(
                              text: TextSpan(
                                text: mainText,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: [
                                  if (secondaryText.isNotEmpty)
                                    TextSpan(
                                      text: ' $secondaryText',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _addController.text = fullDescription;
                                _suggestions.clear();
                              });
                            },
                          ),
                          if (index < _suggestions.length - 1)
                            const Divider(
                              height: 1,
                              color: Colors.black12,
                              indent: 44,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                // Powered by Google logo
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: RichText(
                      text: TextSpan(
                        text: 'powered by ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        children: const [
                          TextSpan(
                            text: 'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          TextSpan(
                            text: 'o',
                            style: TextStyle(
                              color: Color(0xFFEA4335),
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          TextSpan(
                            text: 'o',
                            style: TextStyle(
                              color: Color(0xFFFBBC05),
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          TextSpan(
                            text: 'g',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          TextSpan(
                            text: 'l',
                            style: TextStyle(
                              color: Color(0xFF34A853),
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          TextSpan(
                            text: 'e',
                            style: TextStyle(
                              color: Color(0xFFEA4335),
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

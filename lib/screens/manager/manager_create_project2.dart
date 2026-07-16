import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftsmart/screens/manager/manager_create_com.dart';
import 'package:shiftsmart/services/company_service.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/widgets/custom_date_picker.dart';
import 'package:shiftsmart/models/company.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/models/project.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';

class Managercreateproject2 extends StatefulWidget {
  final String name;
  final String description;
  final String additionalRemark;
  final Project? project;

  const Managercreateproject2({
    super.key,
    required this.name,
    required this.description,
    required this.additionalRemark,
    this.project,
  });

  @override
  State<Managercreateproject2> createState() => _Managercreateproject2State();
}

class _Managercreateproject2State extends State<Managercreateproject2> {
  // Controllers
  final TextEditingController _datedueController = TextEditingController();
  final TextEditingController _startdateController = TextEditingController();
  final TextEditingController _enddateController = TextEditingController();

  // Data
  List<Company> allCom = [];
  int? _selectedComId; // Track ID instead of Name String
  String _selectedStatus = 'Active';
  final List<String> _statusOptions = const ['Active', 'Completed'];

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    fetchCompanies().then((_) {
      if (widget.project != null) {
        _selectedStatus = _normalizeStatus(widget.project!.status);

        // Safe check for null dates
        if (widget.project!.projectDue.isNotEmpty) {
          _datedueController.text = _dateOnly(widget.project!.projectDue);
        }
        if (widget.project!.startDate.isNotEmpty) {
          _startdateController.text = _dateOnly(widget.project!.startDate);
        }
        if (widget.project!.endDate.isNotEmpty) {
          _enddateController.text = _dateOnly(widget.project!.endDate);
        }

        // Find the company ID that matches the company name (case-insensitive & trimmed)
        final existingCom = allCom
            .where((c) =>
                c.name.trim().toLowerCase() ==
                widget.project!.companyName.trim().toLowerCase())
            .firstOrNull;

        if (existingCom != null) {
          setState(() {
            _selectedComId = existingCom.id;
          });
        } else {
          setState(() {});
        }
      }
    });
  }

  String _normalizeStatus(String value) {
    final normalized = value.trim().toLowerCase();
    for (final status in _statusOptions) {
      if (status.toLowerCase() == normalized) return status;
    }
    return 'Active';
  }

  // --- Fetch Companies ---
  Future<void> fetchCompanies() async {
    try {
      final companies = await CompanyService().fetchCompanies();
      if (mounted) {
        setState(() {
          allCom = companies;
        });
      }
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final initialDate = _parseDate(controller.text) ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: datePickerThemeBuilder);
    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() => controller.text = formattedDate);
    }
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  String _dateOnly(String value) {
    final parsed = _parseDate(value);
    if (parsed != null) {
      return DateFormat('yyyy-MM-dd').format(parsed);
    }
    return value.split('T').first;
  }

  String _dateTimeUtc(String value) {
    return '${_dateOnly(value)}T00:00:00Z';
  }

  // --- Submit Logic ---
  Future<void> _submitProjectData() async {
    // 1. Validation
    if (_datedueController.text.isEmpty ||
        _startdateController.text.isEmpty ||
        _enddateController.text.isEmpty ||
        _selectedComId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    final startDate = _parseDate(_startdateController.text);
    final endDate = _parseDate(_enddateController.text);
    final projectDue = _parseDate(_datedueController.text);

    if (startDate == null || endDate == null || projectDue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select valid project dates")),
      );
      return;
    }

    if (endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("End Date cannot be earlier than Start Date")),
      );
      return;
    }

    final projectData = {
      "Name": widget.name, // Capitalized Keys
      "CompanyId": _selectedComId, // Capitalized Keys
      "Description": widget.description,
      "AdditionalRemarks": widget.additionalRemark,
      "ProjectDue": _dateTimeUtc(_datedueController.text),
      "StartDate": _dateTimeUtc(_startdateController.text),
      "EndDate": _dateTimeUtc(_enddateController.text),
      "Status": _selectedStatus,
    };

    if (widget.project != null) {
      projectData["ProjectId"] = widget.project!.projectId;
    }

    bool success;

    // 2. API Call
    if (widget.project != null) {
      success = await ProjectService()
          .updateProject(widget.project!.projectId, projectData);
    } else {
      success = await ProjectService().addProject(projectData);
    }

    // 3. Success Handling
    if (mounted) {
      if (success) {
        SuccessDialog.show(
          context,
          title: widget.project != null ? "Project Updated" : "Project Created",
          message: widget.project != null
              ? "Project details have been successfully updated."
              : "New project has been created successfully.",
          buttonText: "Ok",
          onPressed: () {
            // Because you came from Step 1, we just need to pop backward twice.
            // This preserves the state of the BottomNavbar, keeping you exactly on the "PROJECTS" tab!
            int count = 0;
            Navigator.of(context).popUntil((route) {
              return count++ >= 2;
            });
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit project")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.project != null;

    return Scaffold(
      drawer: const Sidenav(),
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const Background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _WizardShell(
                title: isEditMode ? 'UPDATE PROJECT' : 'CREATE PROJECT',
                onClose: () => Navigator.pop(context),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        children: [
                          _StepIntro(step: 'Step 2 of 2'),
                          const SizedBox(height: 18),
                          _SectionPanel(
                            title: 'Schedule and Ownership',
                            subtitle:
                                'Set project timeline, organization, and status.',
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final twoColumns = constraints.maxWidth >= 620;
                                if (!twoColumns) {
                                  return Column(
                                    children: [
                                      _buildDateField('Project Due Date',
                                          _datedueController,
                                          required: true),
                                      const SizedBox(height: 18),
                                      _buildStatusDropdown(),
                                      const SizedBox(height: 18),
                                      _buildDateField(
                                          'Start Date', _startdateController,
                                          required: true),
                                      const SizedBox(height: 18),
                                      _buildDateField(
                                          'End Date', _enddateController,
                                          required: true),
                                      const SizedBox(height: 18),
                                      _buildDropdownCompany(),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildDateField(
                                              'Project Due Date',
                                              _datedueController,
                                              required: true),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(child: _buildStatusDropdown()),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildDateField('Start Date',
                                              _startdateController,
                                              required: true),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: _buildDateField(
                                              'End Date', _enddateController,
                                              required: true),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    _buildDropdownCompany(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Row(
                        children: [
                          _ActionButton(
                            text: 'Back',
                            onPressed: () => Navigator.pop(context),
                            secondary: true,
                          ),
                          const Spacer(),
                          _ActionButton(
                            text:
                                isEditMode ? 'Update Project' : 'Save Project',
                            onPressed: _submitProjectData,
                            success: true,
                            width: 190,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper: Date Field ---
  Widget _buildDateField(
    String label,
    TextEditingController controller, {
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, required: required),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: _fieldDecoration(
            hintText: 'yyyy-mm-dd',
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month_outlined,
                  color: Colors.white, size: 22),
              onPressed: () => _selectDate(context, controller),
            ),
          ),
          onTap: () => _selectDate(context, controller),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Project Status', required: true),
        const SizedBox(height: 8),
        _SelectBox<int>(
          value: allCom.any((company) => company.id == _selectedComId)
              ? _selectedComId
              : null,
          hint: allCom.isEmpty ? 'No companies available' : 'Select a company',
          items: allCom.map((company) => company.id).toList(),
          labelFor: (id) {
            return allCom.firstWhere((company) => company.id == id).name;
          },
          onChanged: allCom.isEmpty
              ? (_) {}
              : (value) => setState(() => _selectedComId = value),
        ),
      ],
    );
  }

  // --- UI Helper: Company Dropdown ---
  Widget _buildDropdownCompany() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel('Company', required: true),
            const Spacer(),
            TextButton.icon(
              onPressed: _openCreateCompany,
              icon: const Icon(Icons.add_box, size: 18),
              label: const Text('Add Company'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF84E5F4),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SelectBox<int>(
          value: _selectedComId,
          hint: 'Select a company',
          items: allCom.map((company) => company.id).toList(),
          labelFor: (id) {
            return allCom.firstWhere((company) => company.id == id).name;
          },
          onChanged: (value) => setState(() => _selectedComId = value),
        ),
      ],
    );
  }

  Future<void> _openCreateCompany() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const Managercreatecom()),
    );

    if (created == true) {
      await fetchCompanies();
    }
  }
}

class _WizardShell extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget child;

  const _WizardShell({
    required this.title,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF10182A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                Positioned(
                  right: 14,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: 30,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  final String step;

  const _StepIntro({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Complete all required fields to create a project.',
              style: TextStyle(
                color: Color(0xFFD9DEEA),
                fontSize: 16,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A4159).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF3A82A5)),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Color(0xFF8BE6F4),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF202738).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF84E5F4),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFA9AFBE),
              fontSize: 16,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        children: [
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFFF675E)),
            ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({Widget? suffixIcon, String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFFE8ECF5)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFF252B3C),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF84E5F4), width: 1.4),
    ),
  );
}

class _SelectBox<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T item) labelFor;
  final ValueChanged<T?> onChanged;

  const _SelectBox({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF252B3C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          dropdownColor: const Color(0xFF252B3C),
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelFor(item),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool secondary;
  final bool success;
  final double? width;

  const _ActionButton({
    required this.text,
    required this.onPressed,
    this.secondary = false,
    this.success = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = success
        ? const LinearGradient(
            colors: [Color(0xFF43CFC1), Color(0xFF5B6FE8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : secondary
            ? const LinearGradient(
                colors: [Color(0xFF1B3A4B), Color(0xFF2E3D7A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF43CFC1), Color(0xFF5B6FE8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              );

    final icon = success
        ? Icons.check_circle_outline_rounded
        : secondary
            ? Icons.arrow_back_rounded
            : null;

    return SizedBox(
      height: 52,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null
              ? Icon(icon, color: Colors.white, size: 20)
              : const SizedBox.shrink(),
          label: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

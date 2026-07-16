import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftsmart/models/company.dart';
import 'package:shiftsmart/models/project.dart';
import 'package:shiftsmart/screens/manager/manager_create_com.dart';
import 'package:shiftsmart/services/company_service.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/custom_date_picker.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Managercreateproject extends StatefulWidget {
  final Project? project;

  const Managercreateproject({this.project, super.key});

  @override
  State<Managercreateproject> createState() => _ManagercreateprojectState();
}

class _ManagercreateprojectState extends State<Managercreateproject> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _additionalController = TextEditingController();
  final TextEditingController _datedueController = TextEditingController();
  final TextEditingController _startdateController = TextEditingController();
  final TextEditingController _enddateController = TextEditingController();

  final List<String> _statusOptions = const ['Active', 'Completed'];
  List<Company> allCom = [];
  int? _selectedComId;
  String _selectedStatus = 'Active';

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _prefillProject();
    fetchCompanies().then((_) => _selectExistingCompany());
  }

  void _prefillProject() {
    final project = widget.project;
    if (project == null) return;

    _nameController.text = project.name;
    _descController.text = project.description;
    _additionalController.text = project.additionalRemark;
    _selectedStatus = _normalizeStatus(project.status);

    if (project.projectDue.isNotEmpty) {
      _datedueController.text = _dateOnly(project.projectDue);
    }
    if (project.startDate.isNotEmpty) {
      _startdateController.text = _dateOnly(project.startDate);
    }
    if (project.endDate.isNotEmpty) {
      _enddateController.text = _dateOnly(project.endDate);
    }
  }

  void _selectExistingCompany() {
    final project = widget.project;
    if (project == null || allCom.isEmpty || !mounted) return;

    final matches = allCom.where(
      (company) =>
          company.name.trim().toLowerCase() ==
          project.companyName.trim().toLowerCase(),
    );

    if (matches.isNotEmpty) {
      setState(() => _selectedComId = matches.first.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _additionalController.dispose();
    _datedueController.dispose();
    _startdateController.dispose();
    _enddateController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String value) {
    final normalized = value.trim().toLowerCase();
    for (final status in _statusOptions) {
      if (status.toLowerCase() == normalized) return status;
    }
    return 'Active';
  }

  Future<void> fetchCompanies() async {
    try {
      final companies = await CompanyService().fetchCompanies();
      if (mounted) {
        setState(() => allCom = companies);
      }
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final initialDate = _parseDate(controller.text) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: datePickerThemeBuilder,
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
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

  Future<void> _submitProjectData() async {
    if (_nameController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _datedueController.text.trim().isEmpty ||
        _startdateController.text.trim().isEmpty ||
        _enddateController.text.trim().isEmpty ||
        _selectedComId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
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
          content: Text("End Date cannot be earlier than Start Date"),
        ),
      );
      return;
    }

    final projectData = {
      "Name": _nameController.text.trim(),
      "CompanyId": _selectedComId,
      "Description": _descController.text.trim(),
      "AdditionalRemarks": _additionalController.text.trim(),
      "ProjectDue": _dateTimeUtc(_datedueController.text),
      "StartDate": _dateTimeUtc(_startdateController.text),
      "EndDate": _dateTimeUtc(_enddateController.text),
      "Status": _selectedStatus,
    };

    final project = widget.project;
    if (project != null) {
      projectData["ProjectId"] = project.projectId;
    }

    final success = project != null
        ? await ProjectService().updateProject(project.projectId, projectData)
        : await ProjectService().addProject(projectData);

    if (!mounted) return;

    if (success) {
      SuccessDialog.show(
        context,
        title: project != null ? "Project Updated" : "Project Created",
        message: project != null
            ? "Project details have been successfully updated."
            : "New project has been created successfully.",
        buttonText: "Ok",
        onPressed: () => Navigator.pop(context, true),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit project")),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.project != null;

    return Scaffold(
      drawer: const Sidenav(),
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(showBackButton: true),
      body: Stack(
        children: [
          const Background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _FormShell(
                title: isEditMode ? 'UPDATE PROJECT' : 'CREATE PROJECT',
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                        children: [
                          _SectionPanel(
                            title: 'Project Details',
                            subtitle:
                                'Complete the project information, schedule, and ownership.',
                            child: Column(
                              children: [
                                _buildTextField(
                                  'Name',
                                  _nameController,
                                  required: true,
                                ),
                                const SizedBox(height: 18),
                                _buildTextField(
                                  'Description',
                                  _descController,
                                  required: true,
                                  minLines: 4,
                                ),
                                const SizedBox(height: 18),
                                _buildTextField(
                                  'Additional Remarks',
                                  _additionalController,
                                  minLines: 3,
                                ),
                                const SizedBox(height: 18),
                                _buildDateField(
                                  'Project Due Date',
                                  _datedueController,
                                  required: true,
                                ),
                                const SizedBox(height: 18),
                                _buildStatusDropdown(),
                                const SizedBox(height: 18),
                                _buildDateField(
                                  'Start Date',
                                  _startdateController,
                                  required: true,
                                ),
                                const SizedBox(height: 18),
                                _buildDateField(
                                  'End Date',
                                  _enddateController,
                                  required: true,
                                ),
                                const SizedBox(height: 18),
                                _buildDropdownCompany(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _ActionButton(
                                text: 'Cancel',
                                onPressed: () => Navigator.pop(context),
                                secondary: true,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ActionButton(
                                  text: isEditMode
                                      ? 'Update Project'
                                      : 'Save Project',
                                  onPressed: _submitProjectData,
                                  success: true,
                                ),
                              ),
                            ],
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int minLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, required: required),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : 6,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: _fieldDecoration(),
        ),
      ],
    );
  }

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
        _SelectBox<String>(
          value: _selectedStatus,
          hint: 'Select status',
          items: _statusOptions,
          labelFor: (status) => status,
          onChanged: (value) {
            if (value != null) setState(() => _selectedStatus = value);
          },
        ),
      ],
    );
  }

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
}

class _FormShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormShell({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: child),
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
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 430 ? 14.0 : 20.0;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
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

  const _ActionButton({
    required this.text,
    required this.onPressed,
    this.secondary = false,
    this.success = false,
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

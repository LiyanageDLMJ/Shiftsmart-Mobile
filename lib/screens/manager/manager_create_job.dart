import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shiftsmart/services/job_service.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/services/site_service.dart';
import 'package:shiftsmart/widgets/custom_date_picker.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/models/job_role.dart';
import 'package:shiftsmart/models/job_role_type.dart';
import 'package:shiftsmart/models/project.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';
import 'package:shiftsmart/widgets/manager_screen_style.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';

class ManagerCreateJob extends StatefulWidget {
  final Job? existingJob;
  const ManagerCreateJob({super.key, this.existingJob});

  @override
  State<ManagerCreateJob> createState() => _ManagerCreateJobState();
}

class _ManagerCreateJobState extends State<ManagerCreateJob> {
  // Controllers
  final TextEditingController _jobNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Data Lists
  List<Project> _projects = [];
  List<Site> _sites = [];
  List<JobRoleType> _jobRoleTypes = [];
  final List<JobRole> _selectedJobRoles = [];

  // Selections
  Project? _selectedProject;
  Site? _selectedSite;
  File? _selectedImage;

  // UI State
  bool _isInitializing = true;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _initializeData();
  }

  @override
  void dispose() {
    _jobNameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // --- 1. ROBUST INITIALIZATION LOGIC ---
  Future<void> _initializeData() async {
    final existingJob = widget.existingJob;
    if (existingJob != null) {
      _populateExistingJobFields(existingJob);
    }

    final projectsFuture = ProjectService().fetchAllProjects().catchError((e) {
      debugPrint("Error loading projects for job form: $e");
      return <Project>[];
    });
    final sitesFuture = SiteService().fetchAllSites().catchError((e) {
      debugPrint("Error loading sites for job form: $e");
      return <Site>[];
    });
    final roleTypesFuture = JobService().fetchJobRoleType().catchError((e) {
      debugPrint("Error loading job role types for job form: $e");
      return <JobRoleType>[];
    });

    try {
      final allProjects = await projectsFuture;
      final allSites = await sitesFuture;
      final allJobRoleTypes = await roleTypesFuture;

      Project? initialProject;
      Site? initialSite;
      List<JobRole> initialRoles = [];

      if (existingJob != null) {
        try {
          initialProject =
              allProjects.firstWhere((p) => p.projectId == existingJob.projectId);
        } catch (e) {
          debugPrint(
              "Warning: Project ID ${existingJob.projectId} not found in list.");
        }

        if (initialProject != null) {
          try {
            initialSite = allSites.firstWhere((s) =>
                s.siteId == existingJob.siteId &&
                s.projectId == initialProject!.projectId);
          } catch (e) {
            debugPrint(
                "Warning: Site ID ${existingJob.siteId} not found for this project.");
          }
        }

        initialRoles =
            _withRoleTypeNames(existingJob.jobRoles, allJobRoleTypes);
        if (existingJob.jobId != 0) {
          try {
            final jobRolesFromServer =
                await JobService().fetchJobRole(existingJob.jobId);
            if (jobRolesFromServer.isNotEmpty) {
              initialRoles =
                  _withRoleTypeNames(jobRolesFromServer, allJobRoleTypes);
            }
          } catch (e) {
            debugPrint("Error fetching existing job roles: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _projects = allProjects;
          _sites = allSites;
          _jobRoleTypes = allJobRoleTypes;
          _selectedProject = initialProject;
          _selectedSite = initialSite;
          _selectedJobRoles.clear();
          _selectedJobRoles.addAll(initialRoles);
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint("Critical Error initializing data: $e");
      if (mounted) {
        setState(() => _isInitializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load form data. Please retry.')),
        );
      }
    }
  }

  void _populateExistingJobFields(Job job) {
    _jobNameController.text = job.title;
    _descriptionController.text = job.description;
    _startDateController.text = _dateOnly(job.startDate);
    _endDateController.text = _dateOnly(job.jobDueDate);
  }

  String _dateOnly(String value) {
    if (value.trim().isEmpty) return '';
    return value.split('T').first.split(' ').first;
  }

  List<JobRole> _withRoleTypeNames(
    List<JobRole> roles,
    List<JobRoleType> roleTypes,
  ) {
    return roles.map((role) {
      final matchingType = roleTypes.where((t) => t.id == role.jobRoleTypeId);
      final roleName = matchingType.isNotEmpty
          ? matchingType.first.name
          : (role.roleName.isNotEmpty ? role.roleName : 'Unknown Role');

      return JobRole(
        jobRoleTypeId: role.jobRoleTypeId,
        estimatedTime: role.estimatedTime,
        numberOfRoles: role.numberOfRoles,
        notes: role.notes,
        roleName: roleName,
      );
    }).toList();
  }

  // --- Helper: Get Sites for current Project ---
  List<Site> get sitesForSelectedProject {
    if (_selectedProject == null) return [];
    return _sites
        .where((site) => site.projectId == _selectedProject!.projectId)
        .toList();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: datePickerThemeBuilder);
    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  // --- Validation ---
  bool _validate() {
    // Section 1 validation
    if (_jobNameController.text.isEmpty) {
      _showError("Job name is required.");
      return false;
    }
    if (_descriptionController.text.isEmpty) {
      _showError("Description is required.");
      return false;
    }
    if (_startDateController.text.isEmpty) {
      _showError("Start Date is required.");
      return false;
    }
    if (_endDateController.text.isEmpty) {
      _showError("Due Date is required.");
      return false;
    }
    if (_selectedProject == null) {
      _showError("Please select a Project.");
      return false;
    }
    // Section 2 validation
    if (_selectedSite == null) {
      _showError("Please select a Site.");
      return false;
    }
    if (_selectedJobRoles.isEmpty) {
      _showError("Please add at least one job role.");
      return false;
    }
    final hasInvalidResourceValues = _selectedJobRoles.any(
      (role) => role.numberOfRoles <= 0 || role.estimatedTime <= 0,
    );
    if (hasInvalidResourceValues) {
      _showError("Resource count and time must be greater than 0.");
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Job Roles Logic ---
  List<JobRoleType> _availableRoleTypes({int? excludingIndex}) {
    final selectedRoleIds = _selectedJobRoles
        .asMap()
        .entries
        .where((entry) => entry.key != excludingIndex)
        .map((entry) => entry.value.jobRoleTypeId)
        .toSet();

    return _jobRoleTypes
        .where((roleType) => !selectedRoleIds.contains(roleType.id))
        .toList();
  }

  void _addJobRole() {
    final availableRoleTypes = _availableRoleTypes();

    if (availableRoleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No more resources available to add.")),
      );
      return;
    }

    final roleType = availableRoleTypes.first;

    setState(() {
      _selectedJobRoles.add(
        JobRole(
          jobRoleTypeId: roleType.id,
          roleName: roleType.name,
          estimatedTime: 8,
          numberOfRoles: 1,
          notes: "",
        ),
      );
    });
  }

  void _removeJobRole(int index) {
    setState(() {
      _selectedJobRoles.removeAt(index);
    });
  }

  // --- Image Picker ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 768,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // --- 2. SUBMIT ACTION ---
  Future<void> _submitJobAction() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    String startDate = "${_startDateController.text}T00:00:00Z";
    String endDate = "${_endDateController.text}T00:00:00Z";

    final jobData = {
      "title": _jobNameController.text,
      "description": _descriptionController.text,
      "projectId": _selectedProject!.projectId,
      "siteId": _selectedSite!.siteId,
      "startDate": startDate,
      "jobDueDate": endDate,
      "jobRoles": _selectedJobRoles.map((role) => role.toJson()).toList(),
    };

    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool success = false;
    String errorMessage = "";

    try {
      if (widget.existingJob != null) {
        if (_selectedImage != null) {
          success = await JobService().updateJobWithImage(
            widget.existingJob!.jobId,
            jobData,
            _selectedImage!,
          );
        } else {
          success =
              await JobService().updateJob(widget.existingJob!.jobId, jobData);
        }
      } else {
        if (_selectedImage != null) {
          success =
              await JobService().createJobWithImage(jobData, _selectedImage!);
        } else {
          final result = await JobService().addJob(jobData);
          success = result != null && result == 1;
        }
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      success = false;
    }

    if (mounted) Navigator.pop(context); // Dismiss Loading

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        SuccessDialog.show(
          context,
          title: widget.existingJob != null ? "Job Updated" : "Job Created",
          message: widget.existingJob != null
              ? "The job details have been updated successfully."
              : "New job created successfully!",
          buttonText: "Ok",
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const Bottomnavbar(selectedIndex: 2)),
              (Route<dynamic> route) => false,
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.isEmpty
                  ? 'Failed to save job'
                  : 'Failed: $errorMessage',
            ),
          ),
        );
      }
    }
  }

  // --- Image Picker Modal ---
  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A3243),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take a Photo',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.white),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    }

    final existingImageUrl = widget.existingJob?.jobImageUrl.trim() ?? '';
    if (existingImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildRemoteJobImage(existingImageUrl),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          color: Colors.white70,
          size: 48,
        ),
        SizedBox(height: 16),
        Text(
          "Tap to upload an image",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRemoteJobImage(String imageUrl) {
    if (imageUrl.toLowerCase().startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return _buildImageErrorPlaceholder();
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImageErrorPlaceholder(),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.white54,
        size: 44,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingJob != null;

    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          drawer: const Sidenav(),
          appBar: const Uppernavbar(showBackButton: true),
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ManagerFormShell(
                title: isEditMode ? "UPDATE JOB" : "CREATE JOB",
                child: _isInitializing
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: ManagerScreenStyle.cyan))
                    : Column(
                        children: [
                          // ── Scrollable form area ──
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                              children: [
                                // ── Section 1: Job Details ──
                                ManagerSectionPanel(
                                  title: 'Job Details',
                                  subtitle:
                                      'Add the job name, description, schedule, and project.',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInputField("Name",
                                          _jobNameController,
                                          required: true),
                                      const SizedBox(height: 18),
                                      _buildInputField(
                                        "Description",
                                        _descriptionController,
                                        maxLines: 3,
                                        required: true,
                                      ),
                                      const SizedBox(height: 18),
                                      _buildDateField(
                                          "Start Date", _startDateController),
                                      const SizedBox(height: 18),
                                      _buildDateField(
                                          "Due Date", _endDateController),
                                      const SizedBox(height: 18),
                                      _buildProjectDropdown(),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // ── Section 2: Site & Resources ──
                                ManagerSectionPanel(
                                  title: 'Site and Resources',
                                  subtitle:
                                      'Choose the worksite and assign the required role types.',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSiteDropdown(),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Select Resources",
                                            style: TextStyle(
                                              color: ManagerScreenStyle.cyan,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          IconButton.filled(
                                            onPressed: _addJobRole,
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  ManagerScreenStyle.fieldBg,
                                              foregroundColor: Colors.white,
                                            ),
                                            icon:
                                                const Icon(Icons.add_rounded),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _selectedJobRoles.length,
                                        itemBuilder: (context, index) {
                                          return _buildRoleCard(
                                              index, _selectedJobRoles[index]);
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // ── Section 3: Job Media ──
                                ManagerSectionPanel(
                                  title: 'Job Media',
                                  subtitle:
                                      'Attach an optional image for this job.',
                                  child: GestureDetector(
                                    onTap: _showImageSourceSelection,
                                    child: Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: ManagerScreenStyle.fieldBg,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            width: 1.5),
                                      ),
                                      child: _buildJobImagePreview(),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),

                          // ── Bottom Buttons ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                            child: Row(
                              children: [
                                ManagerActionButton(
                                  text: "Cancel",
                                  icon: Icons.arrow_back_rounded,
                                  secondary: true,
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: ManagerActionButton(
                                    text: _isSaving
                                        ? (isEditMode
                                            ? "Updating..."
                                            : "Saving...")
                                        : (isEditMode
                                            ? "Update Job"
                                            : "Save Job"),
                                    icon: Icons.check_circle_rounded,
                                    onPressed:
                                        _isSaving ? () {} : _submitJobAction,
                                  ),
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
    );
  }

  // --- UI Helper: Role Card ---
  Widget _buildRoleCard(int index, JobRole role) {
    if (_jobRoleTypes.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E3545),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    role.roleName.isNotEmpty ? role.roleName : 'Job Role',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeJobRole(index),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.redAccent, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCardField(
                    label: "Count:",
                    initialValue: role.numberOfRoles,
                    onChanged: (v) {
                      setState(() => _selectedJobRoles[index].numberOfRoles = v);
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildCardField(
                    label: "Time(Hrs):",
                    initialValue: role.estimatedTime,
                    onChanged: (v) {
                      setState(
                          () => _selectedJobRoles[index].estimatedTime = v);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final currentRoleType = _jobRoleTypes.firstWhere(
      (type) => type.id == role.jobRoleTypeId,
      orElse: () => _jobRoleTypes.first,
    );
    final availableRoleTypes = _availableRoleTypes(excludingIndex: index);
    final dropdownRoleTypes = availableRoleTypes.any(
      (type) => type.id == currentRoleType.id,
    )
        ? availableRoleTypes
        : [currentRoleType, ...availableRoleTypes];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ManagerScreenStyle.tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: ManagerScreenStyle.fieldBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<JobRoleType>(
                    value: currentRoleType,
                    onChanged: (newType) {
                      if (newType != null) {
                        setState(() {
                          _selectedJobRoles[index].jobRoleTypeId = newType.id;
                          _selectedJobRoles[index].roleName = newType.name;
                        });
                      }
                    },
                    dropdownColor: ManagerScreenStyle.fieldBg,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    iconEnabledColor: Colors.white70,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: dropdownRoleTypes.map((roleType) {
                      return DropdownMenuItem(
                        value: roleType,
                        child: Text(roleType.name),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _removeJobRole(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCardField(
                  label: "Count:",
                  initialValue: role.numberOfRoles,
                  onChanged: (v) {
                    setState(() => _selectedJobRoles[index].numberOfRoles = v);
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildCardField(
                  label: "Time(Hrs):",
                  initialValue: role.estimatedTime,
                  onChanged: (v) {
                    setState(() => _selectedJobRoles[index].estimatedTime = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final TextInputFormatter _positiveNumberFormatter =
      TextInputFormatter.withFunction(
    (oldValue, newValue) {
      final parsed = int.tryParse(newValue.text);
      if (parsed == null || parsed <= 0) return oldValue;
      return newValue;
    },
  );

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.10 : 0.04),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white70 : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildCardField({
    required String label,
    required int initialValue,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: ManagerScreenStyle.fieldBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _buildStepperButton(
                  icon: Icons.remove_rounded,
                  onTap: initialValue > 1
                      ? () => onChanged(initialValue - 1)
                      : null,
                ),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$label-$initialValue'),
                    initialValue: initialValue.toString(),
                    onChanged: (val) {
                      int? parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        onChanged(parsed);
                      }
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _positiveNumberFormatter,
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _buildStepperButton(
                  icon: Icons.add_rounded,
                  onTap: () => onChanged(initialValue + 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Generic UI Helpers ---
  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManagerFieldLabel(label, required: required),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: managerFieldDecoration(),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManagerFieldLabel(label, required: true),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: managerFieldDecoration(
            hintText: 'yyyy-mm-dd',
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white70),
              onPressed: () => _selectDate(context, controller),
            ),
          ),
          onTap: () => _selectDate(context, controller),
        ),
      ],
    );
  }

  Widget _buildProjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ManagerFieldLabel("Project", required: true),
        const SizedBox(height: 8),
        ManagerSelectBox<int>(
          value: _selectedProject?.projectId,
          hint: 'Select the project',
          items: _projects.map((project) => project.projectId).toList(),
          labelFor: (id) =>
              _projects.firstWhere((project) => project.projectId == id).name,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedProject =
                  _projects.firstWhere((p) => p.projectId == value);
              final sites = sitesForSelectedProject;
              _selectedSite = sites.isNotEmpty ? sites.first : null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSiteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ManagerFieldLabel("Site", required: true),
        const SizedBox(height: 8),
        ManagerSelectBox<int>(
          value: sitesForSelectedProject
                  .any((s) => s.siteId == _selectedSite?.siteId)
              ? _selectedSite?.siteId
              : null,
          hint: 'Select a site',
          items: sitesForSelectedProject.map((site) => site.siteId).toList(),
          labelFor: (id) => sitesForSelectedProject
              .firstWhere((s) => s.siteId == id)
              .siteName,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedSite =
                  sitesForSelectedProject.firstWhere((s) => s.siteId == value);
            });
          },
        ),
      ],
    );
  }
}


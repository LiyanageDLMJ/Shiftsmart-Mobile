import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/models/project.dart' as model;
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/screens/manager/manager_create_job.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/manager_screen_style.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/services/job_service.dart';

class ManagerJobView extends StatefulWidget {
  final Job job;
  final bool embedded;

  const ManagerJobView({
    super.key,
    required this.job,
    this.embedded = false,
  });

  @override
  State<ManagerJobView> createState() => _ManagerJobViewState();
}

class _ManagerJobViewState extends State<ManagerJobView> {
  final ProjectService _projectService = ProjectService();

  model.Project? project;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    fetchProject();
  }

  Future<void> fetchProject() async {
    try {
      final projects = await _projectService.fetchAllProjects();
      if (!mounted) return;
      setState(() {
        project = projects.firstWhere(
          (p) => p.projectId == widget.job.projectId,
          orElse: () => model.Project(
            projectId: 0,
            name: 'Unknown Project',
            estimatedTime: 0,
            location: 'Unknown',
            description: '',
            additionalRemark: '',
            projectDue: '',
            startDate: '',
            endDate: '',
            companyName: '',
            status: '',
            sites: [],
          ),
        );
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load projects $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: ManagerScreenStyle.cyan,
                ),
              ),
            )
          : _buildDetailsPanel();
    }

    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const Uppernavbar(showBackButton: true),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: ManagerScreenStyle.cyan,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1040),
                            child: _buildDetailsPanel(),
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

  Widget _buildDetailsPanel() {
    final jobSiteName = widget.job.siteName?.trim() ?? '';
    final location = jobSiteName.isNotEmpty
        ? jobSiteName
        : project?.sites
            .firstWhere(
              (s) => s.siteId == widget.job.siteId,
              orElse: () => Site(
                siteId: 0,
                projectId: widget.job.projectId,
                siteName: 'Unknown Location',
                latitude: '',
                longitude: '',
                geoFenceType: '',
                geoCoordinates: '',
                radius: 0,
              ),
            )
            .siteName ??
            'Unknown Location';
    final isCompleted = widget.job.status.trim().toLowerCase() == 'completed';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262D3F).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 820
                        ? 3
                        : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                    final spacing = 16.0;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 12,
                      children: [
                        _detailTile(
                          width,
                          'PROJECT',
                          project?.name ?? 'Unknown Project',
                          Icons.workspaces_rounded,
                        ),
                        _detailTile(
                          width,
                          'LOCATION',
                          location,
                          Icons.location_on_rounded,
                        ),
                        _detailTile(
                          width,
                          'ESTIMATED TIME',
                          '${widget.job.totalEstimatedTime} Hrs',
                          Icons.hourglass_empty_rounded,
                        ),
                        _detailTile(
                          width,
                          'STATUS',
                          widget.job.status,
                          Icons.flag_rounded,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _textPanel(
                  'DESCRIPTION',
                  widget.job.description.isNotEmpty
                      ? widget.job.description
                      : 'No description available.',
                ),
                const SizedBox(height: 12),
                _jobImagePanel(),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCompleted)
                  ManagerActionButton(
                    text: 'Mark as Completed',
                    icon: Icons.check_circle_rounded,
                    onPressed: () async {
                      final success =
                          await JobService().completeJob(widget.job.jobId);

                      if (success && mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                if (!isCompleted) const SizedBox(width: 12),
                ManagerActionButton(
                  text: 'Update',
                  icon: Icons.edit_rounded,
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) =>
                            ManagerCreateJob(existingJob: widget.job),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 64, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JOB DETAILS',
            style: TextStyle(
              color: ManagerScreenStyle.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.job.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _statusBadge(widget.job.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailTile(double width, String label, String value, IconData icon) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ManagerScreenStyle.tileBg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.trim().isEmpty ? 'Not provided' : value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: ManagerScreenStyle.cyan, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _textPanel(String title, String body) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ManagerScreenStyle.tileBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ManagerScreenStyle.cyan,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobImagePanel() {
    final imageUrl = widget.job.jobImageUrl.trim();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ManagerScreenStyle.tileBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.image_rounded,
                  color: ManagerScreenStyle.cyan, size: 18),
              SizedBox(width: 8),
              Text(
                'JOB IMAGE',
                style: TextStyle(
                  color: ManagerScreenStyle.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (imageUrl.isEmpty)
            Text(
              'No image available',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.56),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildJobImage(imageUrl),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobImage(String imageUrl) {
    if (imageUrl.toLowerCase().startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(imageUrl.split(',').last),
          fit: BoxFit.cover,
        );
      } catch (_) {
        return _imageErrorPlaceholder();
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageErrorPlaceholder(),
    );
  }

  Widget _imageErrorPlaceholder() {
    return Container(
      color: Colors.black.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: Colors.white54,
        size: 42,
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        status.trim().isEmpty ? 'UNKNOWN' : status.trim().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
      case 'in progress':
      case 'inprogress':
        return const Color(0xFFFFFF2E);
      case 'completed':
      case 'complete':
        return const Color(0xFF8BE6B4);
      case 'pending':
      case 'scheduled':
        return const Color(0xFFFFC56D);
      default:
        return ManagerScreenStyle.cyan;
    }
  }

  String _formatDate(String dateTimeString) {
    if (dateTimeString.contains('T')) {
      return dateTimeString.split('T')[0];
    }
    return dateTimeString;
  }
}

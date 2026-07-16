import 'package:flutter/material.dart';
import 'package:shiftsmart/screens/manager/manager_create_project1.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/models/project.dart';

class Managerprojectview extends StatefulWidget {
  final Project? project;
  final bool embedded;

  const Managerprojectview({
    required this.project,
    this.embedded = false,
    super.key,
  });

  @override
  State<Managerprojectview> createState() => _ManagerprojectviewState();
}

class _ManagerprojectviewState extends State<Managerprojectview> {
  static const _pageBg = Color(0xFF0B1020);
  static const _panelBg = Color(0xFF262D3F);
  static const _tileBg = Color(0xFF1B2335);
  static const _cyan = Color(0xFF77E4F7);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildDetailsPanel();
    }

    return Scaffold(
      backgroundColor: _pageBg,
      drawer: const Sidenav(),
      appBar: const Uppernavbar(showBackButton: true),
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
    );
  }

  Widget _buildDetailsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg.withValues(alpha: 0.94),
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
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProjectInfo(),
                const SizedBox(height: 24),
                _buildTextSections(),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildActionButtons(),
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
            'PROJECT DETAILS',
            style: TextStyle(
              color: _cyan,
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
                _valueOrFallback(widget.project!.name, 'Untitled Project'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _statusBadge(widget.project!.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    final label =
        status.trim().isEmpty ? 'UNKNOWN' : status.trim().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildProjectInfo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        final spacing = 16.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            _detailTile(
              width: itemWidth,
              label: 'START DATE',
              value: _formatDate(widget.project!.startDate),
              icon: Icons.calendar_month_rounded,
            ),
            _detailTile(
              width: itemWidth,
              label: 'END DATE',
              value: _formatDate(widget.project!.endDate),
              icon: Icons.calendar_month_rounded,
            ),
            _detailTile(
              width: itemWidth,
              label: 'ESTIMATED TIME',
              value: widget.project!.estimatedTime <= 0
                  ? 'Not specified'
                  : '${widget.project!.estimatedTime} Hrs',
              icon: Icons.hourglass_empty_rounded,
            ),
            _detailTile(
              width: itemWidth,
              label: 'DUE DATE',
              value: _formatDate(widget.project!.projectDue),
              icon: Icons.calendar_month_rounded,
            ),
            _detailTile(
              width: itemWidth,
              label: 'LOCATION',
              value: _valueOrFallback(widget.project!.location, 'Not provided'),
              icon: Icons.location_on_rounded,
            ),
            _detailTile(
              width: itemWidth,
              label: 'COMPANY',
              value:
                  _valueOrFallback(widget.project!.companyName, 'Not provided'),
              icon: Icons.business_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _detailTile({
    required double width,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _tileBg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                    value,
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
            Icon(icon, color: _cyan, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSections() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final children = [
          _textPanel(
            title: 'DESCRIPTION',
            body:
                _valueOrFallback(widget.project!.description, 'No description'),
          ),
          _textPanel(
            title: 'REMARKS',
            body: _valueOrFallback(
                widget.project!.additionalRemark, 'No remarks'),
          ),
        ];

        if (!isWide) {
          return Column(
            children: [
              children.first,
              const SizedBox(height: 16),
              children.last,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children.first),
            const SizedBox(width: 16),
            Expanded(child: children.last),
          ],
        );
      },
    );
  }

  Widget _textPanel({required String title, required String body}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _tileBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _cyan,
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

  Widget _buildActionButtons() {
    final normalizedStatus = widget.project!.status.trim().toLowerCase();
    final isCompleted =
        normalizedStatus == 'completed' || normalizedStatus == 'complete';

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (!isCompleted) _actionButton(
          text: 'Complete',
          icon: Icons.check_circle_rounded,
          gradient: const [Color(0xFF34C8E8), Color(0xFF4E4AF2)],
          onPressed: _markComplete,
        ),
        _actionButton(
          text: 'Update',
          icon: Icons.edit_rounded,
          gradient: const [Color(0xFF34C8E8), Color(0xFF4E4AF2)],
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => Managercreateproject(project: widget.project),
              ),
            );
            if (result == true && mounted) {
              Navigator.pop(context, true);
            }
          },
        ),
      ],
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return _valueOrFallback(rawDate, 'Not provided');
    }
  }

  String _valueOrFallback(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'null' ||
        trimmed.toLowerCase().startsWith('no ')) {
      return fallback;
    }
    return trimmed;
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
        return const Color(0xFFFFC56D);
      default:
        return _cyan;
    }
  }

  void _markComplete() async {
    final success =
        await ProjectService().updateProject(widget.project!.projectId, {
      "name": widget.project!.name,
      "description": widget.project!.description,
      "additionalRemarks": widget.project!.additionalRemark,
      "estimatedTime": widget.project!.estimatedTime,
      "location": widget.project!.location,
      "projectDue": widget.project!.projectDue,
      "startDate": widget.project!.startDate,
      "endDate": widget.project!.endDate,
      "companyName": widget.project!.companyName,
      "status": "Completed",
    });
    if (success) {
      setState(() {
        widget.project!.status = "Completed";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project marked as completed')),
        );
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete project')),
      );
    }
  }
}

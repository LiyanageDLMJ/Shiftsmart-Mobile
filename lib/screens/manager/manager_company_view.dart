import 'package:flutter/material.dart';
import 'package:shiftsmart/models/company.dart';
import 'package:shiftsmart/screens/manager/manager_create_com.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Managercompanyview extends StatefulWidget {
  final Company company;
  final bool embedded;

  const Managercompanyview({
    super.key,
    required this.company,
    this.embedded = false,
  });

  @override
  State<Managercompanyview> createState() => _ManagercompanyviewState();
}

class _ManagercompanyviewState extends State<Managercompanyview> {
  static const _pageBg = Color(0xFF0B1020);
  static const _panelBg = Color(0xFF262D3F);
  static const _tileBg = Color(0xFF1B2335);
  static const _cyan = Color(0xFF77E4F7);

  Company get company => widget.company;

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
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCompanyInfo(),
                const SizedBox(height: 24),
                _textPanel(
                  title: 'ADDRESS',
                  body:
                      _valueOrFallback(company.address, 'No address provided'),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
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
            'COMPANY DETAILS',
            style: TextStyle(
              color: _cyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _valueOrFallback(company.name, 'Untitled Company'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _statusBadge('Company'),
        ],
      ),
    );
  }

  Widget _statusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _cyan.withValues(alpha: 0.6)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: _cyan,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildCompanyInfo() {
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
              label: 'CONTACT PERSON',
              value: _valueOrFallback(company.ContactPerson, 'Not provided'),
              icon: Icons.person_rounded,
            ),
            _detailTile(
              width: itemWidth,
              label: 'CONTACT NUMBER',
              value: _valueOrFallback(company.phoneNumber, 'Not provided'),
              icon: Icons.phone_rounded,
            ),
            _detailTile(
              width: itemWidth,
              label: 'LOCATION',
              value: _valueOrFallback(company.address, 'Not provided'),
              icon: Icons.location_on_rounded,
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
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: [
        _actionButton(
          text: 'Update',
          icon: Icons.edit_rounded,
          gradient: const [Color(0xFF34C8E8), Color(0xFF4E4AF2)],
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => Managercreatecom(company: company),
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

  String _valueOrFallback(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'null' ||
        trimmed.toLowerCase().startsWith('no ')) {
      return fallback;
    }
    return trimmed;
  }
}

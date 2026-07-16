import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';

class OrganizationSelector extends StatefulWidget {
  final VoidCallback? onTenantSwitched;

  const OrganizationSelector({super.key, this.onTenantSwitched});

  @override
  State<OrganizationSelector> createState() => _OrganizationSelectorState();
}

class _OrganizationSelectorState extends State<OrganizationSelector> {
  @override
  void initState() {
    super.initState();
    // Ensure tenant list is loaded when this widget first appears.
    // This makes the organization dropdown available immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _seedTenantList();
    });
  }

  Future<void> _seedTenantList() async {
    final tp = context.read<TenantProvider>();
    final up = context.read<UserProvider>();
    final userTenants = up.tenants
        .whereType<Map>()
        .map((tenant) => Map<String, dynamic>.from(tenant))
        .toList();

    if (userTenants.length > tp.tenants.length) {
      tp.setTenants(userTenants);
    }

    if (tp.tenants.length <= 1) {
      await tp.loadTenants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantProvider>(
      builder: (context, tenantProvider, child) {
        final tenants = tenantProvider.tenants;
        final selectedOrg = tenantProvider.selectedOrganization;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final menuWidth = screenWidth < 392 ? screenWidth - 40 : 320.0;
        final menuMaxHeight = screenHeight * 0.5;

        // Build a popup menu of all known tenants. The current selection
        // is shown in the button, and selecting a different tenant triggers
        // tenantProvider.switchTenant.
        return PopupMenuButton<Map<String, dynamic>>(
          offset: const Offset(-16, 12),
          color: const Color(0xFF111827),
          constraints: BoxConstraints(
            maxWidth: menuWidth,
            maxHeight: menuMaxHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          elevation: 10,
          padding: EdgeInsets.zero,
          onSelected: (Map<String, dynamic> tenant) async {
            final name = (tenant['name'] ??
                    tenant['Name'] ??
                    tenant['tenantName'] ??
                    tenant['TenantName'] ??
                    tenant['organizationName'] ??
                    '')
                .toString();
            if (name == selectedOrg && name.isNotEmpty) return;

            // When the user picks a new organization, ask TenantProvider
            // to switch tenant context. The provider handles backend
            // switching and notifies all listeners.
            await tenantProvider.switchTenant(tenant);
            if (widget.onTenantSwitched != null) {
              widget.onTenantSwitched!();
            }
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2430),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.business,
                      color: Color(0xFF2DA6FF),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        selectedOrg.isNotEmpty
                            ? selectedOrg
                            : 'Select Organization',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
          itemBuilder: (BuildContext context) {
            List<PopupMenuEntry<Map<String, dynamic>>> items = [];

            // Header with the active organization summary.
            items.add(
              PopupMenuItem<Map<String, dynamic>>(
                enabled: false,
                padding: EdgeInsets.zero,
                height: 70,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121827),
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE ORGANIZATION',
                        style: TextStyle(
                          color: Color(0xFF9AA4B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF55C994),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              selectedOrg.isNotEmpty
                                  ? selectedOrg
                                  : 'Select Organization',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

            // Tenants
            for (var tenant in tenants) {
              final name = (tenant['name'] ??
                      tenant['Name'] ??
                      tenant['tenantName'] ??
                      tenant['TenantName'] ??
                      tenant['organizationName'] ??
                      'Unnamed')
                  .toString();
              final isSelected = name == selectedOrg;

              items.add(
                PopupMenuItem<Map<String, dynamic>>(
                  value: tenant,
                  padding: EdgeInsets.zero,
                  height: 44,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1D326D)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.88),
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Color(0xFFA8CBFF),
                            size: 24,
                          )
                      ],
                    ),
                  ),
                ),
              );
            }

            return items;
          },
        );
      },
    );
  }
}

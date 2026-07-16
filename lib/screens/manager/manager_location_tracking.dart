import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/models/site_employee.dart';
import 'package:shiftsmart/services/site_service.dart';

class ManagerLocationTracking extends StatefulWidget {
  final int? siteId;

  const ManagerLocationTracking({super.key, this.siteId});

  @override
  State<ManagerLocationTracking> createState() =>
      _ManagerLocationTrackingState();
}

class _ManagerLocationTrackingState extends State<ManagerLocationTracking> {
  Site? currentSite;
  List<Site> availableSites = [];
  List<SiteEmployee> employees = [];
  bool isLoading = true;
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  LatLng _mapCenter = _defaultMapCenter;
  final double _mapZoom = 15.0;
  List<SiteEmployee> filteredEmployees = [];
  final SiteService _siteService = SiteService();
  Timer? _refreshTimer;
  MapType _mapType = MapType.normal;
  static const LatLng _defaultMapCenter = LatLng(-33.8688, 151.2093);

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _loadAllSites();

    // Auto-refresh locations every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshEmployeeLocations();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllSites() async {
    try {
      final sites = await _siteService.fetchAllSites();

      Site? selected;
      if (widget.siteId != null) {
        try {
          selected = sites.firstWhere(
            (s) => s.siteId == widget.siteId,
          );
        } catch (_) {
          selected = null;
        }
      }

      setState(() {
        availableSites = sites;
        currentSite = selected;
        if (selected != null) {
          _mapCenter = _siteLatLng(selected) ?? _defaultMapCenter;
        } else {
          _mapCenter = _defaultMapCenter;
        }
      });

      if (selected != null) {
        await _refreshEmployeeLocations();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _mapCenter = _defaultMapCenter;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _onSiteSelected(Site? site) {
    setState(() {
      currentSite = site;
      if (site != null) {
        final sitePosition = _siteLatLng(site);
        _mapCenter = sitePosition ?? _defaultMapCenter;
      } else {
        employees = [];
        filteredEmployees = [];
        _markers = {};
        _mapCenter = _defaultMapCenter;
      }
    });
    if (site != null) {
      _refreshEmployeeLocations();
    } else {
      _fitMapToContent();
    }
  }

  Future<void> _refreshEmployeeLocations() async {
    if (currentSite == null) return;

    try {
      final siteEmployees =
          await _siteService.fetchEmployeesInSite(currentSite!.siteId, currentSite!);

      if (mounted) {
        setState(() {
          employees = siteEmployees;
          filteredEmployees = List.from(siteEmployees);
          isLoading = false;
          _createMarkers(currentSite!, siteEmployees);
        });
        await _fitMapToContent();
      }
    } catch (e) {
      debugPrint("Error refreshing locations: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _createMarkers(Site site, List<SiteEmployee> employees) {
    final markers = <Marker>{};
    final sitePosition = _siteLatLng(site);

    if (sitePosition != null) {
      // 1. Site Marker
      markers.add(Marker(
        markerId: MarkerId('site_${site.siteId}'),
        position: sitePosition,
        infoWindow: InfoWindow(
          title: site.siteName,
          snippet: "Radius: ${site.radius}m",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    // 2. Employee Markers
    for (final employee in employees) {
      if (employee.clockInLat != null && employee.clockInLng != null) {
        final double markerHue = employee.isInside
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueRed;
        final distanceText = employee.distance == null
            ? 'Outside fence'
            : 'Outside (${(employee.distance! * 1000).toStringAsFixed(0)}m away)';

        markers.add(Marker(
          markerId: MarkerId('employee_${employee.employeeId}'),
          position: LatLng(employee.clockInLat!, employee.clockInLng!),
          infoWindow: InfoWindow(
            title: employee.name,
            snippet: employee.isInside ? 'Inside Fence' : distanceText,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
        ));
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
    await _fitMapToContent();
  }

  Future<void> _fitMapToContent() async {
    if (!_mapController.isCompleted) return;

    final controller = await _mapController.future;
    final points = <LatLng>[_mapCenter];

    for (final employee in employees) {
      if (employee.clockInLat != null && employee.clockInLng != null) {
        points.add(LatLng(employee.clockInLat!, employee.clockInLng!));
      }
    }

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _mapCenter, zoom: _mapZoom),
        ),
      );
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFromLatLngList(points), 56),
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  LatLng? _siteLatLng(Site site) {
    final lat = double.tryParse(site.latitude ?? '');
    final lng = double.tryParse(site.longitude ?? '');

    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

    // Most bad site records in this app arrive as 0/0 after failed parsing.
    if (lat == 0 && lng == 0) return null;

    return LatLng(lat, lng);
  }

  void onQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = List.from(employees);
      } else {
        filteredEmployees = employees
            .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          drawer: const Sidenav(currentScreen: 'LocationTracking'),
          extendBodyBehindAppBar: true,
          appBar: const Uppernavbar(showBackButton: true),
          body: SafeArea(
            child: Stack(
              children: [
                // Full-screen map
                Positioned.fill(
                  child: _buildMapContent(),
                ),
                // Site Selector at top center
                Positioned(
                  top: 24,
                  left: 16,
                  right: 16,
                  child: _buildSiteSelector(),
                ),
                // Map type toggle - below site selector on left
                Positioned(
                  left: 24,
                  top: 130,
                  child: _buildMapTypeToggle(),
                ),
                // Recenter button - bottom right
                Positioned(
                  right: 24,
                  bottom: 140,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: IconButton(
                      tooltip: 'Recenter',
                      icon: const Icon(Icons.my_location,
                          color: Color(0xFF1F2937)),
                      onPressed: _fitMapToContent,
                    ),
                  ),
                ),
                // Zoom controls - right side
                Positioned(
                  right: 24,
                  bottom: 200,
                  child: _buildZoomControls(),
                ),
                // Bottom Tracking Status Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildTrackingPanel(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _mapCenter,
        zoom: _mapZoom,
      ),
      markers: _markers,
      mapType: _mapType,
      zoomControlsEnabled: false,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      circles: currentSite != null && _siteLatLng(currentSite!) != null
          ? {
              Circle(
                circleId: CircleId('geofence_${currentSite!.siteId}'),
                center: _siteLatLng(currentSite!)!,
                radius: currentSite!.radius ?? 0.0,
                strokeWidth: 2,
                strokeColor: const Color(0xFF6EA8FF),
                fillColor: const Color(0xFF6EA8FF).withValues(alpha: 0.18),
              )
            }
          : {},
    );
  }

  void _showSiteSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filteredSites = availableSites.where((site) {
              return site.siteName.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Dialog(
              backgroundColor: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Site',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search Field
                    TextField(
                      onChanged: (value) {
                        setStateDialog(() {
                          searchQuery = value;
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search site...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Scrollable List
                    Expanded(
                      child: ListView(
                        children: [
                          // Choose a site option
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            title: const Text(
                              'Choose a site',
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                            leading: currentSite == null
                                ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                                : const SizedBox(width: 24),
                            onTap: () {
                              Navigator.pop(context);
                              _onSiteSelected(null);
                            },
                          ),
                          const Divider(color: Colors.white10),
                          if (filteredSites.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'No sites found',
                                  style: TextStyle(color: Color(0xFF9CA3AF)),
                                ),
                              ),
                            )
                          else
                            ...filteredSites.map((site) {
                              final isSelected = currentSite?.siteId == site.siteId;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                title: Text(
                                  site.siteName,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                leading: isSelected
                                    ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                                    : const SizedBox(width: 24),
                                onTap: () {
                                  Navigator.pop(context);
                                  _onSiteSelected(site);
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSiteSelector() {
    final activeCount = employees.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Dropdown row ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "Site" label
              const Text(
                'Site',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              // Full-width dropdown with blue border
              Expanded(
                child: InkWell(
                  onTap: _showSiteSelectionDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentSite?.siteName ?? 'Choose a site',
                            style: TextStyle(
                              color: currentSite == null
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh icon
              GestureDetector(
                onTap: _refreshEmployeeLocations,
                child: const Icon(
                  Icons.refresh,
                  color: Color(0xFF9CA3AF),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // --- Bottom row: hint + active count ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select a site to start tracking',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
              Text(
                '$activeCount active',
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          child: IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6B7280)),
            onPressed: () async {
              final controller = await _mapController.future;
              controller.animateCamera(CameraUpdate.zoomIn());
            },
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          child: IconButton(
            icon: const Icon(Icons.remove, color: Color(0xFF6B7280)),
            onPressed: () async {
              final controller = await _mapController.future;
              controller.animateCamera(CameraUpdate.zoomOut());
            },
          ),
        ),
      ],
    );
  }

  void _showActiveEmployeesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF262A34), Color(0xFF1C2230)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Text(
                          'Tracking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentSite?.siteName ?? '',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  
                  // Content List
                  Flexible(
                    child: employees.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            child: Center(
                              child: Text(
                                'No active employees',
                                style: TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: employees.length,
                            itemBuilder: (context, index) {
                              final employee = employees[index];
                              
                              final initials = employee.name.isNotEmpty
                                  ? employee.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                                  : 'EE';
                              
                              final bool isInside = employee.isInside;
                              final distanceText = employee.distance == null
                                  ? '~0.00 km'
                                  : '~${employee.distance!.toStringAsFixed(2)} km';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2937),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Initials Avatar
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF3B82F6),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            employee.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isInside 
                                                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isInside 
                                                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: isInside 
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFFEF4444),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isInside ? 'Inside Fence' : 'Outside Fence',
                                                  style: TextStyle(
                                                    color: isInside 
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFFEF4444),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Distance
                                    Text(
                                      distanceText,
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrackingPanel() {
    final hasActiveEmployees = currentSite != null && employees.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasActiveEmployees ? _showActiveEmployeesBottomSheet : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tracking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSite == null ? 'No site selected' : '${employees.length} active',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                      if (hasActiveEmployees) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_up,
                          color: Color(0xFF9CA3AF),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currentSite == null
                    ? 'No clocked-in employees for this site.'
                    : employees.isEmpty
                        ? 'No employees currently active'
                        : '${employees.length} employee${employees.length != 1 ? 's' : ''} checked in',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapTypeToggle() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mapTypeButton('Map', MapType.normal),
          Container(
            width: 1,
            height: 36,
            color: Colors.black.withValues(alpha: 0.08),
          ),
          _mapTypeButton('Satellite', MapType.satellite),
        ],
      ),
    );
  }

  Widget _mapTypeButton(String label, MapType mapType) {
    final selected = _mapType == mapType;
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: selected ? Colors.black : const Color(0xFF666666),
        backgroundColor: selected ? Colors.white : const Color(0xFFF9FAFB),
        minimumSize: const Size(78, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      onPressed: () {
        setState(() => _mapType = mapType);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/services/location_service.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class EmployeeTrackingScreen extends StatefulWidget {
  final Site currentSite;
  final int employeeId;

  const EmployeeTrackingScreen({
    super.key,
    required this.currentSite,
    required this.employeeId,
  });

  @override
  State<EmployeeTrackingScreen> createState() => _EmployeeTrackingScreenState();
}

class _EmployeeTrackingScreenState extends State<EmployeeTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = RealLocationService();

  // Stream to listen to location updates
  StreamSubscription<Position>? _positionStream;

  // Markers & Circles
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  // State
  bool _isInside = false;
  CameraPosition? _initialPosition;
  Position? _currentPosition;
  bool _isLoading = true;
  MapType _mapType = MapType.normal;

  // Dark Map Style (Defined locally so it doesn't affect other files)
  final String _mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#242f3e"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#242f3e"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#746855"}]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#38414e"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#212a37"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#17263c"}]
      }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    _setupGeofence();
    _startTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // 1. Draw the Site Geofence (Circle)
  void _setupGeofence() {
    final double lat = double.tryParse(widget.currentSite.latitude ?? '0') ?? 0;
    final double lng =
        double.tryParse(widget.currentSite.longitude ?? '0') ?? 0;
    final double radius = (widget.currentSite.radius ?? 150).toDouble();

    setState(() {
      _initialPosition = CameraPosition(
        target: LatLng(lat, lng),
        zoom: 16,
      );

      _circles.add(
        Circle(
          circleId: const CircleId('site_geofence'),
          center: LatLng(lat, lng),
          radius: radius,
          fillColor: Colors.blue
              .withValues(alpha: 0.15), // Slightly transparent for dark map
          strokeColor: Colors.blueAccent,
          strokeWidth: 2,
        ),
      );

      // Add marker for the Site Center
      _markers.add(
        Marker(
          markerId: const MarkerId('site_center'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: widget.currentSite.siteName),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });
  }

  // 2. Start Live Tracking
  void _startTracking() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    try {
      Position initialPos = await Geolocator.getCurrentPosition();
      _updateMyLocation(initialPos);
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _updateMyLocation(position);
      _locationService.sendLocation(position, widget.employeeId);
    });
  }

  // 3. Update UI Marker
  void _updateMyLocation(Position position) async {
    final double siteLat =
        double.tryParse(widget.currentSite.latitude ?? '0') ?? 0;
    final double siteLng =
        double.tryParse(widget.currentSite.longitude ?? '0') ?? 0;
    final double radius = (widget.currentSite.radius ?? 150).toDouble();

    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      siteLat,
      siteLng,
    );

    bool isInside = distance <= radius;

    if (mounted) {
      setState(() {
        _isInside = isInside;
        _currentPosition = position;

        _markers.removeWhere((m) => m.markerId.value == 'me');
        _markers.add(
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                isInside ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: "You",
              snippet: isInside ? "Inside Site" : "Outside Site",
            ),
          ),
        );
      });
    }
  }

  Future<void> _recenterMap() async {
    if (_currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 17,
        ),
      ));
    }
  }

  Widget _buildMapCard() {
    if (_initialPosition == null || _isLoading) {
      return _buildMapShell(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return _buildMapShell(
      child: Stack(
        children: [
          GoogleMap(
            mapType: _mapType,
            initialCameraPosition: _initialPosition!,
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              controller.setMapStyle(_mapStyle);
            },
            padding: const EdgeInsets.only(bottom: 90, top: 56),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _buildMapTypeToggle(),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 6,
              child: IconButton(
                tooltip: 'Recenter',
                icon: const Icon(Icons.my_location, color: Color(0xFF1F2937)),
                onPressed: _recenterMap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                _isInside ? 'On site' : 'Off site',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isInside ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isInside
                ? 'Ready to clock in and out from this site.'
                : 'Move inside the geofence to resume tracking.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
            ),
          ),
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Current location: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapTypeToggle() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mapTypeButton('Map', MapType.normal),
          Container(width: 1, height: 34, color: const Color(0xFFE5E7EB)),
          _mapTypeButton('Satellite', MapType.satellite),
        ],
      ),
    );
  }

  Widget _mapTypeButton(String label, MapType type) {
    final selected = _mapType == type;
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(84, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: selected ? Colors.black : const Color(0xFF6B7280),
        backgroundColor: selected ? const Color(0xFFF9FAFB) : Colors.white,
      ),
      onPressed: () {
        setState(() => _mapType = type);
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

  Widget _buildMapShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
  }

  Widget _buildSiteHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Site',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.currentSite.siteName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: const Uppernavbar(showBackButton: false),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSiteHeader(),
            const SizedBox(height: 16),
            Expanded(flex: 7, child: _buildMapCard()),
            const SizedBox(height: 18),
            _buildStatusCard(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

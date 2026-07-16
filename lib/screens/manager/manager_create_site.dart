import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:shiftsmart/models/project.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/services/site_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/utils/google_maps_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/manager_screen_style.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';

class Managercreatesite extends StatefulWidget {
  final Site? site;
  final bool embedded;

  const Managercreatesite({super.key, this.site, this.embedded = false});

  @override
  State<Managercreatesite> createState() => _ManagercreatesiteState();
}

class _ManagercreatesiteState extends State<Managercreatesite> {
  // Controllers
  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController =
      TextEditingController(text: "-33.8688");
  final TextEditingController _longitudeController =
      TextEditingController(text: "151.2093");

  // State Variables
  LatLng? _selectedLocation;
  List<Project> allProjects = [];
  int? _selectedProjectId;
  List<Map<String, String>> _suggestions = [];
  String tokenForSession = const Uuid().v4();
  bool _isSaving = false;

  // Services & Maps
  final ProjectService _projectService = ProjectService();
  GoogleMapController? mapController;
  MapType _mapType = MapType.normal;
  static const LatLng _defaultCenter = LatLng(-33.8688, 151.2093);

  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      enableFullScreen();
    }
    fetchProjects();

    // Populate fields if editing
    if (widget.site != null) {
      _siteNameController.text = widget.site!.siteName;
      _addressController.text =
          widget.site!.address ?? ""; // <-- USE ADDRESS HERE
      _latitudeController.text = widget.site!.latitude ?? "-33.8688";
      _longitudeController.text = widget.site!.longitude ?? "151.2093";
      _selectedProjectId = widget.site!.projectId;
    }

    _selectedLocation = _currentLatLng();
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // --- Fetch Projects ---
  Future<void> fetchProjects() async {
    try {
      final projects = await _projectService.fetchAllProjects();
      if (mounted) {
        setState(() {
          allProjects = projects;
        });
      }
    } catch (e) {
      debugPrint("Error fetching projects: $e");
    }
  }

  // --- Map Controller ---
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    final selected = _selectedLocation;
    if (selected != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: selected, zoom: 15),
        ),
      );
    }
  }

  LatLng _currentLatLng() {
    return LatLng(
      double.tryParse(_latitudeController.text.trim()) ??
          _defaultCenter.latitude,
      double.tryParse(_longitudeController.text.trim()) ??
          _defaultCenter.longitude,
    );
  }

  Future<void> _selectLocation(LatLng latLng,
      {bool updateAddress = true}) async {
    setState(() {
      _latitudeController.text = latLng.latitude.toString();
      _longitudeController.text = latLng.longitude.toString();
      _selectedLocation = latLng;
    });

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16),
      ),
    );

    if (!updateAddress) return;

    try {
      final placemarks =
          await geo.placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = [
          place.name,
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .map((part) => part!.trim())
            .toSet()
            .toList();
        if (parts.isNotEmpty) {
          setState(() => _addressController.text = parts.join(', '));
        }
      }
    } catch (e) {
      debugPrint("Reverse geo error: $e");
    }
  }

  // --- Address Lookup (Forward Geocoding) ---
  Future<void> _moveMapToAddress() async {
    final address = _addressController.text;
    if (address.isEmpty) return;

    // Try Google Geocoding API first (much more reliable in simulators than native geocoding)
    try {
      final key = GoogleMapsHelper.apiKey;
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$key";
      final response = await http.get(
        Uri.parse(url),
        headers: GoogleMapsHelper.platformHeaders,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List;
        if (results.isNotEmpty) {
          final location = results.first['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final latLng = LatLng(lat, lng);

          await _selectLocation(latLng, updateAddress: false);
          return;
        }
      }
    } catch (e) {
      debugPrint("Google Geocoding API error: $e");
    }

    // Fallback to native geocoding
    try {
      final locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        await _selectLocation(latLng, updateAddress: false);
      }
    } catch (e) {
      debugPrint("Address lookup failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Address not found on map")),
        );
      }
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return;
    final key = GoogleMapsHelper.apiKey;
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: GoogleMapsHelper.platformHeaders,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['result'];
        if (result != null && result['geometry'] != null) {
          final location = result['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final latLng = LatLng(lat, lng);

          await _selectLocation(latLng, updateAddress: false);
        }
      }
    } catch (e) {
      debugPrint("Place details error: $e");
    }
  }

  // --- Google Places Autocomplete ---
  Future<List<Map<String, String>>> makeSuggestion(String input) async {
    final key = GoogleMapsHelper.apiKey;
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$key&sessiontoken=$tokenForSession";

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
      debugPrint("Autocomplete error: $e");
    }
    return [];
  }

  // --- Submit Site ---
  Future<void> _submitSite() async {
    // 1. Validation
    if (_siteNameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Site Name is required")));
      return;
    }
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Address is required")));
      return;
    }
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a project")));
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a map location")));
      return;
    }

    setState(() => _isSaving = true);

    final siteData = {
      "ProjectId": _selectedProjectId,
      "SiteName": _siteNameController.text.trim(),
      "Address": _addressController.text.trim(),
      "Latitude": double.tryParse(_latitudeController.text.trim()) ?? 0.0,
      "Longitude": double.tryParse(_longitudeController.text.trim()) ?? 0.0,
      "GeoFenceType": "circle",
      "GeoCoordinates": "",
      "Radius": 150.5,
    };

    bool success = false;

    // 2. API Call
    try {
      if (widget.site != null) {
        success = await SiteService().updateSite(widget.site!.siteId, siteData);
      } else {
        success = await SiteService().addSite(siteData);
      }
    } catch (e) {
      debugPrint("Error saving site: $e");
      success = false;
    }

    setState(() => _isSaving = false);

    // 3. Success Handling
    if (mounted) {
      if (success) {
        // --- Show Success Dialog ---
        SuccessDialog.show(
          context,
          title: widget.site != null ? "Site Updated" : "Site Created",
          message: widget.site != null
              ? "The site details have been updated successfully."
              : "New site has been created successfully.",
          buttonText: "OK",
          onPressed: () {
            Navigator.pop(context, true); // Return to list screen with 'true'
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save site")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ManagerFormShell(
      title: widget.site != null ? "UPDATE SITE" : "CREATE SITE",
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
        children: [
          ManagerSectionPanel(
            title: 'Site Details',
            subtitle:
                'Select the project, enter site information, and place the map pin.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownProject(),
                const SizedBox(height: 18),
                const ManagerFieldLabel('Site Name', required: true),
                const SizedBox(height: 8),
                TextField(
                  controller: _siteNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: managerFieldDecoration(
                    hintText: "e.g. Head Office",
                  ),
                ),
                const SizedBox(height: 18),
                _buildSiteAddressField(),
                const SizedBox(height: 18),
                _buildMapPinSection(),
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
                      ? (widget.site != null ? "Updating..." : "Creating...")
                      : (widget.site != null ? "Update Site" : "Save Site"),
                  icon: Icons.check_circle_rounded,
                  onPressed: _isSaving ? () {} : _submitSite,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF363E51), Color(0xFF191E26)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: form,
          ),
        ),
      );
    }

    return Scaffold(
        drawer: const Sidenav(),
        backgroundColor: ManagerScreenStyle.pageBg,
        appBar: const Uppernavbar(
          showBackButton: true,
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: Background()),
            SafeArea(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: form,
            ))
          ],
        ));
  }

  // --- UI Helper: Address Field ---
  Widget _buildSiteAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ManagerFieldLabel("Site Address", required: true),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
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
          onSubmitted: (_) => _moveMapToAddress(),
          decoration: managerFieldDecoration(),
        ),
        const SizedBox(height: 6),
        // Suggestions Dropdown
        if (_suggestions.isNotEmpty)
          Container(
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
                            onTap: () async {
                              _addressController.text = fullDescription;
                              setState(() {
                                _suggestions.clear();
                              });
                              await _getPlaceDetails(suggestion['place_id'] ?? '');
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

  // --- UI Helper: Project Dropdown ---
  Widget _buildDropdownProject() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ManagerFieldLabel("Project", required: true),
        const SizedBox(height: 8),
        ManagerSelectBox<int>(
          value: _selectedProjectId,
          hint: 'Choose a project',
          items: allProjects.map((project) => project.projectId).toList(),
          labelFor: (id) =>
              allProjects.firstWhere((project) => project.projectId == id).name,
          onChanged: (value) => setState(() => _selectedProjectId = value),
        ),
      ],
    );
  }

  // --- UI Helper: Google Map ---
  Widget _buildMapPinSection() {
    final selected = _selectedLocation ?? _currentLatLng();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Map Pin",
            style: TextStyle(
              color: ManagerScreenStyle.cyan,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tap on the map to adjust the exact site coordinates.",
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 18),
          RichText(
            text: const TextSpan(
              text: "Select Location",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: "*", style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: selected,
                      zoom: 15,
                    ),
                    onTap: _selectLocation,
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: selected,
                        infoWindow:
                            const InfoWindow(title: 'Selected location'),
                      ),
                    },
                    mapType: _mapType,
                    zoomControlsEnabled: true,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                  ),
                  _buildMapTypeToggle(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeToggle() {
    return Positioned(
      left: 10,
      top: 10,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        elevation: 3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mapTypeButton('Map', MapType.normal),
            Container(
              width: 1,
              height: 34,
              color: Colors.black.withValues(alpha: 0.08),
            ),
            _mapTypeButton('Satellite', MapType.satellite),
          ],
        ),
      ),
    );
  }

  Widget _mapTypeButton(String label, MapType mapType) {
    final selected = _mapType == mapType;

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: selected ? Colors.black : const Color(0xFF555555),
        backgroundColor: selected ? Colors.white : const Color(0xFFF5F5F5),
        minimumSize: const Size(74, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: () {
        setState(() => _mapType = mapType);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

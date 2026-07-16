import 'package:flutter/material.dart';
import 'package:shiftsmart/models/emergency_contact_model.dart';
import 'package:shiftsmart/services/emergency_contact_service.dart';
import 'package:shiftsmart/services/phone_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/emp_slidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class EmployeeEmergency extends StatefulWidget {
  final PhoneService phoneService;
  const EmployeeEmergency({super.key, required this.phoneService});

  @override
  State<EmployeeEmergency> createState() => _EmployeeEmergencyState();
}

class _EmployeeEmergencyState extends State<EmployeeEmergency> {
  final EmergencyContactService _contactService = EmergencyContactService();
  late final PhoneService _phoneService;
  List<NextOfKin> _contacts = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _phoneService = widget.phoneService;
    enableFullScreen();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final contacts = await _contactService.getContacts();

      if (mounted) {
        setState(() {
          _contacts = contacts;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to load emergency contacts. Please try again later.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is empty!')),
      );
      return;
    }

    try {
      await _phoneService.makePhoneCall(phoneNumber);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')));
      }
    }
  }

  void _handleSosPressed() {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final targetContact = _contacts.first;

    debugPrint(
        "SOS Triggered: Dialing first next of kin ${targetContact.fullName} (${targetContact.mobileNumber})");
    _makePhoneCall(targetContact.mobileNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      drawer: EmpSidenav(
        currentScreen: 'EmployeeEmergency',
      ),
      appBar: Uppernavbar(
        showBackButton: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Background()),
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // addEmergency(context, _loadContacts),

                            const SizedBox(height: 40),
                            titleText(),
                            const SizedBox(height: 40),
                            sosButton(context, _handleSosPressed),
                            const SizedBox(height: 20),
                            ..._contacts.map((contact) => contactItem(
                                context,
                                contact,
                                () => _makePhoneCall(contact.mobileNumber))),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget contactItem(
  BuildContext context,
  NextOfKin contact,
  VoidCallback onCall,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(180, 42, 50, 67),
          Color.fromARGB(180, 34, 40, 52),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      onTap: onCall,
      leading: const Icon(Icons.person_pin, color: Colors.white),
      title: Text(
        contact.fullName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.mobileNumber,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Text(
            contact.relationship,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget titleText() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Help is just a click away!",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: "Click ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: "SOS button",
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: " to call for help.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget sosButton(BuildContext context, VoidCallback onSosPressed) {
  return Center(
    child: Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onSosPressed,
        customBorder: const CircleBorder(),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color.fromARGB(255, 240, 176, 179),
                Color(0xFFFF5A5F),
                Color.fromARGB(255, 221, 19, 26),
                Color(0xFFB71C1C),
              ],
              center: Alignment.center,
              radius: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 246, 237, 237)
                    .withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "SOS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

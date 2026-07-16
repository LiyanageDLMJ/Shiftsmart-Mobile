import 'package:url_launcher/url_launcher.dart';

abstract class PhoneService {
  Future<void> makePhoneCall(String phoneNumber);
}

class RealPhoneService implements PhoneService {
  @override
  Future<void> makePhoneCall(String phoneNumber) async {
    // Remove spaces, dashes, and other non-digit characters except '+'
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri.parse('tel:$cleanNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some devices where canLaunchUrl returns false but launchUrl works
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      throw Exception('Could not launch phone dialer: $e');
    }
  }
}

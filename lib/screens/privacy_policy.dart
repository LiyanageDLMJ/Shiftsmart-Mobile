import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF172033),
        foregroundColor: Colors.white,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ShiftSmart Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Effective date: 10 September 2026',
                    style: TextStyle(color: Color(0xFF647087), fontSize: 14),
                  ),
                  SizedBox(height: 24),
                  _PolicyParagraph(
                    'AIT Services ("we", "us" or "our") operates the '
                    'ShiftSmart mobile application. This policy explains how '
                    'ShiftSmart collects, uses, protects and retains personal '
                    'information.',
                  ),
                  _PolicySection(
                    title: 'Information We Collect',
                    children: [
                      _PolicyParagraph(
                        'Depending on the features used and the user\'s role, '
                        'ShiftSmart may collect:',
                      ),
                      _PolicyBullet(
                          'Identity, contact, employment and profile information.'),
                      _PolicyBullet(
                          'Account, organisation and authentication information.'),
                      _PolicyBullet(
                          'Shift, attendance, break, leave and work-related records.'),
                      _PolicyBullet(
                          'Precise device location during an active shift.'),
                      _PolicyBullet(
                        'Clock-in and clock-out photos, profile images and documents uploaded by the user.',
                      ),
                      _PolicyBullet(
                          'Messages and other information submitted through the app.'),
                      _PolicyBullet(
                        'Device identifiers, push-notification tokens and notification preferences.',
                      ),
                      _PolicyBullet(
                        'Technical and diagnostic information needed to secure and operate the service.',
                      ),
                    ],
                  ),
                  _PolicySection(
                    title: 'Background Location',
                    children: [
                      _PolicyParagraph(
                        'ShiftSmart collects precise location data during an '
                        'active shift, from clock-in until manual or automatic '
                        'clock-out. Location may be collected in the background, '
                        'including when the app is closed or not in use, to '
                        'support attendance, site-boundary monitoring, geofence '
                        'warnings and automatic clock-out. Background location '
                        'tracking stops after clock-out.',
                      ),
                      _PolicyParagraph(
                        'Authorised managers within the user\'s organisation may '
                        'view work-related location information where required '
                        'to manage active shifts and attendance. We do not sell '
                        'location data or share it with third parties for their '
                        'own advertising or marketing purposes.',
                      ),
                    ],
                  ),
                  _PolicySection(
                    title: 'How We Use Information',
                    children: [
                      _PolicyBullet(
                          'Authenticate users and provide ShiftSmart features.'),
                      _PolicyBullet(
                          'Schedule and manage employees, jobs, sites and shifts.'),
                      _PolicyBullet(
                          'Record attendance, breaks, clock-in and clock-out events.'),
                      _PolicyBullet(
                          'Monitor site boundaries during active shifts.'),
                      _PolicyBullet(
                          'Deliver operational and safety notifications.'),
                      _PolicyBullet(
                          'Respond to support, privacy and security requests.'),
                      _PolicyBullet(
                          'Maintain and protect the reliability of the service.'),
                    ],
                  ),
                  _PolicySection(
                    title: 'Service Providers',
                    children: [
                      _PolicyParagraph(
                        'We may use contracted cloud hosting, mapping and '
                        'push-notification providers to process information on '
                        'our behalf. These providers may only process information '
                        'as required to deliver their services and remain subject '
                        'to applicable contractual and legal safeguards. '
                        'ShiftSmart does not use precise location data for advertising.',
                      ),
                    ],
                  ),
                  _PolicySection(
                    title: 'Data Retention',
                    children: [
                      _PolicyParagraph(
                        'Raw precise-location records are retained for up to 90 '
                        'days after a shift ends and are then deleted or '
                        'de-identified. Attendance and employment records may be '
                        'retained for longer where required for business, '
                        'dispute-resolution or legal record-keeping purposes. '
                        'Other personal information is retained only for as long '
                        'as needed for the purposes described in this policy or '
                        'as required by law.',
                      ),
                    ],
                  ),
                  _PolicySection(
                    title: 'Security',
                    children: [
                      _PolicyParagraph(
                        'We use reasonable technical and organisational measures '
                        'designed to protect personal information from misuse, '
                        'loss, interference and unauthorised access, modification '
                        'or disclosure. No storage or transmission method can be '
                        'guaranteed to be completely secure.',
                      ),
                    ],
                  ),
                  _PolicySection(
                    title: 'Your Choices and Rights',
                    children: [
                      _PolicyParagraph(
                        'Users can control device permissions through their '
                        'operating-system settings. Denying location permission '
                        'may prevent clock-in and active-shift site-boundary '
                        'features from working.',
                      ),
                      _PolicyParagraph(
                        'Users may request access to, correction of, or deletion '
                        'of their personal information by emailing '
                        'contact@aitservices.com.au. AIT Services may verify the '
                        'requester\'s identity and retain information where '
                        'required by law or for another permitted purpose.',
                      ),
                    ],
                  ),
                  _PolicySection(
                    title: 'Changes to This Policy',
                    children: [
                      _PolicyParagraph(
                        'We may update this policy when our practices, services '
                        'or legal obligations change. The effective date at the '
                        'top of this page identifies the latest version.',
                      ),
                    ],
                  ),
                  _PolicySection(
                    title: 'Contact Us',
                    children: [
                      _PolicyParagraph(
                        'AIT Services\n'
                        'Website: https://aitservices.com.au/\n'
                        'Email: contact@aitservices.com.au',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PolicySection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  final String text;

  const _PolicyParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3F4A5F),
          fontSize: 15,
          height: 1.55,
        ),
      ),
    );
  }
}

class _PolicyBullet extends StatelessWidget {
  final String text;

  const _PolicyBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF2979FF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF3F4A5F),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

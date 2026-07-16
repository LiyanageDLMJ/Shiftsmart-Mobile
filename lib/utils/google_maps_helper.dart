import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapsHelper {
  /// Get the correct Google Maps API key depending on the current platform.
  /// Falls back to the general `GOOGLE_MAPS_API_KEY` if platform-specific keys are not set.
  static String get apiKey {
    if (Platform.isAndroid) {
      final androidKey = dotenv.env['GOOGLE_MAPS_ANDROID_KEY'];
      if (androidKey != null && androidKey.isNotEmpty) {
        return androidKey;
      }
    } else if (Platform.isIOS) {
      final iosKey = dotenv.env['GOOGLE_MAPS_IOS_KEY'];
      if (iosKey != null && iosKey.isNotEmpty) {
        return iosKey;
      }
    }
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  /// Get HTTP headers required to authenticate restricted API keys for REST API calls.
  static Map<String, String> get platformHeaders {
    if (Platform.isAndroid) {
      return {
        'X-Android-Package': 'com.AIT_MOBILE.shiftsmart',
        'X-Android-Cert': 'E2F79985AC4C279D31845B9D906DED99F6F8FB44',
      };
    } else if (Platform.isIOS) {
      return {
        'X-Ios-Bundle-Identifier': 'au.com.ait.shiftsmart',
      };
    }
    return {};
  }
}

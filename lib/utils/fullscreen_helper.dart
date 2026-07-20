import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void enableFullScreen() {
  _showSystemBars();
}

void disableFullScreen() {
  _showSystemBars();
}

void _showSystemBars() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1C2230),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF1C2230),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

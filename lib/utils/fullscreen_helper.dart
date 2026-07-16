import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void enableFullScreen() {
  _showSystemBars();
}

void disableFullScreen() {
  _showSystemBars();
}

void _showSystemBars() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

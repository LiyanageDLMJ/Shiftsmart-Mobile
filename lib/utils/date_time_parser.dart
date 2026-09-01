import 'package:intl/intl.dart';

DateTime? parseServerDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  if (value is int || value is double) {
    return _parseEpoch(value);
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final numeric = int.tryParse(raw);
  if (numeric != null) {
    return _parseEpoch(numeric);
  }

  final cleaned = raw.replaceAll(RegExp(r'[\s]+'), ' ').trim();
  if (_isDateOnly(cleaned)) {
    final parts = cleaned.split(RegExp(r'[-/]')).map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(cleaned);
  final parsedIso = DateTime.tryParse(cleaned);
  if (parsedIso != null) {
    return hasTimezone ? parsedIso : _asLocalWallClock(parsedIso);
  }

  final patterns = [
    "yyyy-MM-dd HH:mm:ss",
    "yyyy-MM-dd HH:mm",
    "yyyy/MM/dd HH:mm:ss",
    "yyyy/MM/dd HH:mm",
    "dd/MM/yyyy HH:mm:ss",
    "dd/MM/yyyy HH:mm",
    "MM/dd/yyyy HH:mm:ss",
    "MM/dd/yyyy HH:mm",
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.SSS",
    "yyyy-MM-dd'T'HH:mm:ss",
  ];

  for (final pattern in patterns) {
    try {
      final parseAsUtc = hasTimezone || pattern.contains("'Z'");
      final dt = DateFormat(pattern).parseLoose(cleaned, parseAsUtc);
      return parseAsUtc ? dt : _asLocalWallClock(dt);
    } catch (_) {
      continue;
    }
  }

  return null;
}

bool _isDateOnly(String value) {
  return RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$').hasMatch(value);
}

DateTime? parseChatDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) {
    return value;
  }

  if (value is int || value is double) {
    return _parseEpoch(value);
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final numeric = int.tryParse(raw);
  if (numeric != null) {
    return _parseEpoch(numeric);
  }

  final cleaned = raw.replaceAll(RegExp(r'[\s]+'), ' ').trim();
  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(cleaned);
  final parsedIso = DateTime.tryParse(cleaned);
  if (parsedIso != null) {
    return hasTimezone ? parsedIso : _asLocalWallClock(parsedIso);
  }

  final patterns = [
    "yyyy-MM-dd h:mm:ss a",
    "yyyy-MM-dd h:mm a",
    "yyyy/MM/dd h:mm:ss a",
    "yyyy/MM/dd h:mm a",
    "dd/MM/yyyy h:mm:ss a",
    "dd/MM/yyyy h:mm a",
    "MM/dd/yyyy h:mm:ss a",
    "MM/dd/yyyy h:mm a",
    "yyyy-MM-dd HH:mm:ss",
    "yyyy-MM-dd HH:mm",
    "yyyy/MM/dd HH:mm:ss",
    "yyyy/MM/dd HH:mm",
    "dd/MM/yyyy HH:mm:ss",
    "dd/MM/yyyy HH:mm",
    "MM/dd/yyyy HH:mm:ss",
    "MM/dd/yyyy HH:mm",
    "yyyy-MM-dd'T'h:mm:ss a",
    "yyyy-MM-dd'T'h:mm a",
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.SSS",
    "yyyy-MM-dd'T'HH:mm:ss",
  ];

  for (final pattern in patterns) {
    try {
      final parseAsUtc = hasTimezone || pattern.contains("'Z'");
      final parsed = DateFormat(pattern).parseLoose(cleaned, parseAsUtc);
      return parseAsUtc ? parsed : _asLocalWallClock(parsed);
    } catch (_) {
      continue;
    }
  }

  return null;
}

DateTime _asLocalWallClock(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
}

/// Formats a [DateTime] to an ISO 8601 string that includes the timezone offset.
/// This prevents backends from incorrectly interpreting local time as UTC.
String formatDateTimeForServer(DateTime? dt) {
  if (dt == null) return "";

  // If it's already UTC, just return with 'Z'
  if (dt.isUtc) {
    return dt.toIso8601String().endsWith('Z')
        ? dt.toIso8601String()
        : "${dt.toIso8601String()}Z";
  }

  // Get wall clock time string
  String iso = dt.toIso8601String();

  // Calculate offset
  final offset = dt.timeZoneOffset;
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final sign = offset.isNegative ? "-" : "+";

  return "$iso$sign$hours:$minutes";
}

DateTime? _parseEpoch(dynamic value) {
  final epoch = value is double ? value.toInt() : value as int;
  if (epoch.abs() < 10000000000) {
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart'; // Requires 'printing' package
import 'package:pdf/widgets.dart' as pw; // Requires 'pdf' package
import 'package:pdf/pdf.dart';
import 'package:shiftsmart/models/attendance.dart';
import 'package:shiftsmart/services/attendance_service.dart';
import 'package:shiftsmart/utils/date_time_parser.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Managerattendaceview extends StatefulWidget {
  final Attendance attendance;

  const Managerattendaceview({
    super.key,
    required this.attendance,
  });

  @override
  State<Managerattendaceview> createState() => _ManagerattendaceviewState();
}

class _ManagerattendaceviewState extends State<Managerattendaceview> {
  final AttendanceService _attendanceService = AttendanceService();
  List<AttendancePhoto> _clockInPhotos = [];
  List<AttendancePhoto> _clockOutPhotos = [];
  bool _isLoadingEvidence = false;

  @override
  void initState() {
    super.initState();
    _loadMissingEvidence();
    enableFullScreen();
  }

  Future<void> _loadMissingEvidence() async {
    setState(() => _isLoadingEvidence = true);

    try {
      List<AttendancePhoto> clockInPhotos = const [];
      List<AttendancePhoto> clockOutPhotos = const [];

      if (widget.attendance.attendanceId > 0) {
        clockInPhotos = await _attendanceService
            .fetchClockInPhotos(widget.attendance.attendanceId);
        clockOutPhotos = await _attendanceService
            .fetchClockOutPhotos(widget.attendance.attendanceId);
      }

      if (!mounted) return;

      setState(() {
        _clockInPhotos = clockInPhotos;
        _clockOutPhotos = clockOutPhotos;
      });
    } catch (e) {
      debugPrint('Error loading attendance evidence: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvidence = false);
      }
    }
  }

  // --- Helper: Format Date Strings ---
  String formatDateTime(String? dtString) {
    final dt = parseServerDateTime(dtString);
    if (dt == null) return "Not recorded";
    return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
  }

  String _calculateBreakMinutes(String start, String end) {
    final startTime = parseServerDateTime(start);
    final endTime = parseServerDateTime(end);

    if (startTime == null || endTime == null) return "0m";

    final duration = endTime.difference(startTime);
    return "${duration.inMinutes}m";
  }

  // --- Action: Generate PDF ---
  Future<void> generatePdf() async {
    final pdf = pw.Document();

    try {
      // Build the PDF Pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(),
              pw.SizedBox(height: 30),
              _buildMainContent(),
              pw.SizedBox(height: 40),
              _buildTimeSummary(),
              pw.SizedBox(height: 30),
              _buildFooter(),
            ];
          },
        ),
      );

      // Open System Print/Share UI
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Attendance_${widget.attendance.employeeName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating PDF: $e")),
        );
      }
    }
  }

  // --- PDF Component: Header ---
  pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF2563EB), // Professional Blue
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "ATTENDANCE REPORT",
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            "Generated on ${DateFormat('MMMM dd, yyyy at HH:mm').format(DateTime.now())}",
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- PDF Component: Main Info Table ---
  pw.Widget _buildMainContent() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Employee Information",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF374151),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(120),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              _buildTableRow("Employee Name", widget.attendance.employeeName),
              _buildTableRow("Shift Name", widget.attendance.shiftName),
              if (widget.attendance.isEmergency)
                _buildTableRow("Clock Out Type", " EARLY CLOCK-OUT"),
              if (widget.attendance.isEmergency &&
                  widget.attendance.emergencyReason.isNotEmpty)
                _buildTableRow("Early Clock Out Reason",
                    widget.attendance.emergencyReason),
            ],
          ),
        ],
      ),
    );
  }

  // --- PDF Component: Time Calculations ---
  // --- PDF Component: Time Calculations ---
  pw.Widget _buildTimeSummary() {
    final clockIn = parseServerDateTime(widget.attendance.clockInTime);
    final clockOut = parseServerDateTime(widget.attendance.clockOutTime);
    final breakStart = parseServerDateTime(widget.attendance.breakStart);
    final breakEnd = parseServerDateTime(widget.attendance.breakEnd);

    // Calculate durations safely in minutes
    final int totalMins = (clockIn != null && clockOut != null)
        ? clockOut.difference(clockIn).inMinutes
        : 0;

    final int breakMins = (breakStart != null && breakEnd != null)
        ? breakEnd.difference(breakStart).inMinutes
        : 0;

    final int netMins = totalMins > breakMins ? totalMins - breakMins : 0;

    // Helper function to format minutes into "Xh Ym"
    String formatMinutes(int totalMinutes) {
      final int hours = totalMinutes ~/ 60;
      final int minutes = totalMinutes % 60;
      return '${hours}h ${minutes}m';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Time Summary",
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF374151),
          ),
        ),
        pw.SizedBox(height: 15),

        // Grid of Time Cards
        pw.Row(
          children: [
            pw.Expanded(
                child: _buildTimeCard(
                    "Clock In",
                    formatDateTime(widget.attendance.clockInTime),
                    PdfColors.green)),
            pw.SizedBox(width: 10),
            pw.Expanded(
                child: _buildTimeCard(
                    "Clock Out",
                    formatDateTime(widget.attendance.clockOutTime),
                    PdfColors.red)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
                child: _buildTimeCard(
                    "Break Start",
                    formatDateTime(widget.attendance.breakStart),
                    PdfColors.orange)),
            pw.SizedBox(width: 10),
            pw.Expanded(
                child: _buildTimeCard(
                    "Break End",
                    formatDateTime(widget.attendance.breakEnd),
                    PdfColors.blue)),
          ],
        ),
        pw.SizedBox(height: 20),

        // Totals Box
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF9FAFB),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem("Total Hours", formatMinutes(totalMins)),
              _buildSummaryItem("Break Time", formatMinutes(breakMins)),
              _buildSummaryItem("Net Working Hours", formatMinutes(netMins)),
            ],
          ),
        ),
      ],
    );
  }

  // --- PDF Helper: Time Card ---
  pw.Widget _buildTimeCard(String title, String time, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            time,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // --- PDF Helper: Summary Item ---
  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2563EB),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromInt(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // --- PDF Helper: Table Row ---
  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF6B7280),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  // --- PDF Helper: Footer ---
  pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromInt(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            "This report was automatically generated by the ShiftSmart system.",
            style: pw.TextStyle(
              fontSize: 10,
              color: const PdfColor.fromInt(0xFF9CA3AF),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(
        showBackButton: true,
      ),
      drawer: const Sidenav(),
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Detailed Information Card
                Card(
                  color: const Color(0xFF2C3440),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Attendance Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 30),
                        _buildInfoRow(
                            "Employee", widget.attendance.employeeName),
                        _buildInfoRow("Shift", widget.attendance.shiftName),
                        const SizedBox(height: 10),
                        _buildInfoRow("Clock In",
                            formatDateTime(widget.attendance.clockInTime)),
                        _buildInfoRow("Clock Out",
                            formatDateTime(widget.attendance.clockOutTime)),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                            "Break Time",
                            _calculateBreakMinutes(widget.attendance.breakStart,
                                widget.attendance.breakEnd)),
                        if (widget.attendance.isEmergency &&
                            widget.attendance.emergencyReason.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(color: Colors.orange, height: 20),
                          _buildInfoRow("Early Clock Out Reason",
                              widget.attendance.emergencyReason,
                              isWarning: true),
                        ],
                        const SizedBox(height: 10),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        const Text(
                          "Attendance Evidence",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildEvidenceGallery(),
                        if (_isLoadingEvidence)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          )
                        else if (_clockInPhotos.isEmpty &&
                            _clockOutPhotos.isEmpty)
                          const Text(
                            "No attendance photos recorded for this shift.",
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 30),

                // Generate Report Button
                Center(
                  child: GestureDetector(
                    onTap: () {
                      generatePdf(); // Triggers system print dialog
                    },
                    child: Container(
                      width: 200,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34C8E8), Color(0xFF4E4AF2)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Generate Report",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.white,
                            size: 22,
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
      ),
    );
  }

  // UI Helper: Data Rows
  Widget _buildInfoRow(String title, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$title:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWarning ? Colors.orange : Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isWarning ? Colors.orange : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceGallery() {
    final sections = <Widget>[
      if (_clockInPhotos.isNotEmpty)
        _buildEvidenceSection(
          "Clock In",
          _clockInPhotos,
        ),
      if (_clockOutPhotos.isNotEmpty)
        _buildEvidenceSection(
          "Clock Out",
          _clockOutPhotos,
        ),
    ];

    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          if (index > 0) const SizedBox(height: 14),
          sections[index],
        ],
      ],
    );
  }

  Widget _buildEvidenceSection(String label, List<AttendancePhoto> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photos.length == 1 ? label : "$label (${photos.length})",
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = photos.length == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: photos
                  .map((photo) => SizedBox(
                        width: tileWidth,
                        child: _buildEvidenceBox(photo.url),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEvidenceBox(String url) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildAttendanceImage(url, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildAttendanceImage(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildAttendanceImage(String value, {required BoxFit fit}) {
    final bytes = _decodeImageBytes(value);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _imageErrorPlaceholder(),
      );
    }

    return Image.network(
      value,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _imageErrorPlaceholder(),
    );
  }

  Widget _imageErrorPlaceholder() {
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white24),
    );
  }

  Uint8List? _decodeImageBytes(String value) {
    final trimmed = value.trim();
    final commaIndex = trimmed.indexOf(',');
    final base64Value =
        trimmed.toLowerCase().startsWith('data:image') && commaIndex != -1
            ? trimmed.substring(commaIndex + 1)
            : trimmed;

    if (base64Value.startsWith('http://') ||
        base64Value.startsWith('https://')) {
      return null;
    }

    try {
      return base64Decode(base64Value);
    } catch (_) {
      return null;
    }
  }
}

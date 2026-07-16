import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/models/report_employee.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:circulito/circulito.dart';

class ManagerEmployeePerformanceViewOverallReport extends StatefulWidget {
  final ReportEmployee data;
  final List<Employee> allEmployees;

  const ManagerEmployeePerformanceViewOverallReport({
    super.key,
    required this.data,
    required this.allEmployees,
  });

  @override
  State<ManagerEmployeePerformanceViewOverallReport> createState() =>
      _ManagerEmployeePerformanceViewOverallReportState();
}

class _ManagerEmployeePerformanceViewOverallReportState
    extends State<ManagerEmployeePerformanceViewOverallReport> {
  // ADDED: GlobalKey for capturing the chart as an image for the PDF
  final GlobalKey chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final firstName = data.EmployeeName.split(' ')[0];
    final employee = widget.allEmployees.firstWhere(
      (emp) => emp.employeeId == data.EmployeeId,
      orElse: () => Employee(
        employeeId: data.EmployeeId,
        firstName: data.EmployeeName,
        profilePicture: '',
        nextOfKins: [],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(showBackButton: true),
      drawer: const Sidenav(),
      body: Stack(
        children: [
          const Positioned(child: Background()),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF2A3243), Color(0xFF1C2230)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "OVERALL EMPLOYEE PERFORMANCE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ... (Header Row with Avatar and details is unchanged)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: (employee.profilePicture != null &&
                                  employee.profilePicture!
                                      .startsWith('data:image'))
                              ? MemoryImage(base64Decode(
                                  employee.profilePicture!.split(',').last))
                              : (employee.profilePicture != null &&
                                      employee.profilePicture!.isNotEmpty)
                                  ? NetworkImage(employee.profilePicture!)
                                  : null,
                          child: (employee.profilePicture == null ||
                                  employee.profilePicture!.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "Employee",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Generated: ${DateFormat('yyyy/MM/dd HH:mm').format(data.GeneratedAt)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Text(
                              "Report ID: ${data.ReportId}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              "Generated By: ${data.GeneratedBy}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildRow("Employee Name:", data.EmployeeName),
                    _buildRow(
                        "Number Of Shifts:", data.NumberOfShifts.toString()),
                    _buildRow("Leaves Taken:", data.Leaves.toString()),
                    _buildRow("Total Break Hours:",
                        data.TotalBreakHours.toStringAsFixed(2)),
                    _buildRow("Late Arrivals:", data.LateArrivals.toString()),
                    _buildRow(
                        "Tasks Completed:", data.TasksCompleted.toString()),
                    const SizedBox(height: 15),
                    const Text(
                      "Overall Performance Score",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${data.PerformanceScore.toInt()}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent[400],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // RESTORED: Circulito chart for performance score
                    Center(
                      child: RepaintBoundary(
                        key: chartKey,
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Layer 1: Dark blue background ring
                              Circulito(
                                padding: 5,
                                strokeWidth: 10,
                                sections: [
                                  CirculitoSection(
                                    value: 1, // Full circle
                                    decoration:
                                        const CirculitoDecoration.fromColor(
                                            Color.fromARGB(255, 3, 4, 94)),
                                  ),
                                ],
                                maxSize: 130,
                              ),
                              // Layer 2: The main performance arc
                              Circulito(
                                padding: 0,
                                strokeWidth: 27,
                                isCentered: true,
                                startPoint: StartPoint.top,
                                strokeCap: CirculitoStrokeCap.butt,
                                sections: [
                                  CirculitoSection(
                                    value: data.PerformanceScore / 100,
                                    decoration:
                                        const CirculitoDecoration.fromColor(
                                            Color.fromARGB(255, 0, 119, 182)),
                                  ),
                                ],
                                maxSize: 150,
                              ),
                              // Layer 3: The white circle in the center for the text
                              Circulito(
                                strokeWidth: 40,
                                // This section creates the solid white circle background
                                sections: [
                                  CirculitoSection(
                                    value: 1, // Full circle
                                    decoration:
                                        const CirculitoDecoration.fromColor(
                                            Colors.white),
                                  ),
                                ],
                                maxSize: 75,
                                child: Text(
                                  "${data.PerformanceScore.toInt()}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 18,
                                    // Text color changed to black to be visible on the white circle
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // RESTORED: PDF generation button with correct onTap action
                    Center(
                      child: GestureDetector(
                        onTap: () => _generatePdf(context),
                        child: Container(
                          width: 180,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF34C8E8),
                                Color(0xFF4E4AF2),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Generate PDF",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.picture_as_pdf_outlined,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          Text(value,
              style: const TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  // ADDED: Helper function to capture the chart widget as an image
  Future<Uint8List?> _captureChartAsImage(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }

  // ADDED: Full PDF generation logic, adapted for the Overall Report
  void _generatePdf(BuildContext context) async {
    final data = widget.data;
    final chartBytes = await _captureChartAsImage(chartKey);
    final pdf = pw.Document();

    final chartImage = chartBytes != null ? pw.MemoryImage(chartBytes) : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Overall Employee Performance Report",
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
                pw.SizedBox(height: 24),
                _pdfRow("Employee Name", data.EmployeeName),
                _pdfRow("Report Generated At",
                    DateFormat('yyyy-MM-dd HH:mm').format(data.GeneratedAt)),
                _pdfRow("Report ID", data.ReportId.toString()),
                pw.SizedBox(height: 20),
                _pdfRow("Number of Shifts", data.NumberOfShifts.toString()),
                _pdfRow("Leaves Taken", data.Leaves.toString()),
                _pdfRow("Total Break Hours",
                    data.TotalBreakHours.toStringAsFixed(2)),
                _pdfRow("Late Arrivals", data.LateArrivals.toString()),
                _pdfRow("Tasks Completed", data.TasksCompleted.toString()),
                pw.SizedBox(height: 20),
                pw.Text("Overall Performance",
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black)),
                pw.Text("${data.PerformanceScore.toInt()}%",
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green)),
                pw.SizedBox(height: 24),
                if (chartImage != null)
                  pw.Center(
                    child: pw.Image(chartImage, width: 120, height: 120),
                  ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ADDED: Helper widget for creating rows in the PDF document
  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              "$label:",
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

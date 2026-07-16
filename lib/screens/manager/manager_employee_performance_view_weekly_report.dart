import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/models/weekly_report_employee.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:circulito/circulito.dart';

class ManagerEmployeePerformanceViewWeeklyReport extends StatefulWidget {
  final WeeklyReportEmployee data;
  final List<Employee> allEmployees;

  const ManagerEmployeePerformanceViewWeeklyReport({
    super.key,
    required this.data,
    required this.allEmployees,
  });

  @override
  State<ManagerEmployeePerformanceViewWeeklyReport> createState() =>
      _ManagerEmployeePerformanceViewWeeklyReportState();
}

class _ManagerEmployeePerformanceViewWeeklyReportState
    extends State<ManagerEmployeePerformanceViewWeeklyReport> {
  final GlobalKey chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final firstName = data.employeeName.split(' ')[0];
    final employee = widget.allEmployees.firstWhere(
      (emp) => emp.employeeId == data.employeeId,
      orElse: () => Employee(
        employeeId: data.employeeId,
        firstName: data.employeeName,
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
                    colors: [
                      Color(0xFF2A3243),
                      Color(0xFF1C2230),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "WEEKLY EMPLOYEE PERFORMANCE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                              "Week: ${data.reportStart} - ${data.reportEnd}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Text(
                              "Date: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              "Generated By: System",
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
                    _buildRow("Employee Name:", data.employeeName),
                    _buildRow("No of Shifts:", data.numberOfShifts.toString()),
                    _buildRow("Total Break Hours:",
                        data.totalBreakHours.toStringAsFixed(2)),
                    _buildRow("Late Arrivals:", data.lateArrivals.toString()),
                    const SizedBox(height: 15),
                    const Text(
                      "Overall Performance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${data.performanceScore.toInt()}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent[400],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ADDED: Chart and PDF Button sections
                    Center(
                      child: RepaintBoundary(
                        key: chartKey,
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Circulito(
                                padding: 5,
                                strokeWidth: 10,
                                sections: [
                                  CirculitoSection(
                                    value: 1,
                                    decoration:
                                        const CirculitoDecoration.fromColor(
                                            Color.fromARGB(255, 3, 4, 94)),
                                  ),
                                ],
                                maxSize: 130,
                              ),
                              Circulito(
                                padding: 0,
                                strokeWidth: 27,
                                isCentered: true,
                                startPoint: StartPoint.top,
                                strokeCap: CirculitoStrokeCap.butt,
                                sections: [
                                  CirculitoSection(
                                    value: data.performanceScore / 100,
                                    decoration:
                                        const CirculitoDecoration.fromColor(
                                            Color.fromARGB(255, 0, 119, 182)),
                                  ),
                                ],
                                maxSize: 150,
                              ),
                              Circulito(
                                strokeWidth: 40,
                                sections: [
                                  CirculitoSection(
                                    value: 1,
                                    decoration:
                                        const CirculitoDecoration.fromColor(
                                            Colors.white),
                                  ),
                                ],
                                maxSize: 75,
                                child: Text(
                                  "${data.performanceScore.toInt()}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 18,
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

  // ADDED: Helper functions for PDF generation
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
                pw.Text("Weekly Employee Performance Report",
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
                pw.SizedBox(height: 24),
                _pdfRow("Employee Name", data.employeeName),
                _pdfRow("Week", "${data.reportStart} - ${data.reportEnd}"),
                _pdfRow("Generated At",
                    DateFormat('yyyy-MM-dd').format(DateTime.now())),
                pw.SizedBox(height: 20),
                _pdfRow("No of Shifts", data.numberOfShifts.toString()),
                _pdfRow("Total Break Hours",
                    data.totalBreakHours.toStringAsFixed(2)),
                _pdfRow("Late Arrivals", data.lateArrivals.toString()),
                pw.SizedBox(height: 20),
                pw.Text("Overall Performance",
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black)),
                pw.Text("${data.performanceScore.toInt()}%",
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

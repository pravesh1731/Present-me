import 'dart:convert';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/constants.dart';
import '../../viewmodels/teacher_class/teacher_class_bloc.dart';

class DownloadAttendancePage extends StatefulWidget {
  const DownloadAttendancePage({super.key});

  @override
  State<DownloadAttendancePage> createState() => _DownloadAttendancePageState();
}

class _DownloadAttendancePageState extends State<DownloadAttendancePage> {
  static const _pageBg = Color(0xFFF4FBF7);

  final Map<int, DateTimeRange?> _customRanges = {};

  // Track which class + type is downloading
  // key: "$index-pdf" or "$index-excel"
  final Map<String, bool> _downloading = {};

  bool _isDownloading(int index, String type) =>
      _downloading['$index-$type'] == true;

  Future<void> downloadAttendance({
    required String classCode,
    required String className,
    required int index,
    DateTimeRange? range,
    required String type,
  }) async {
    final key = '$index-$type';

    setState(() => _downloading[key] = true);

    final token = getToken();
    String url = "$baseUrl/teachers/class-attendance/$classCode";

    if (range != null) {
      final start =
          "${range.start.year}-${range.start.month.toString().padLeft(2, '0')}-${range.start.day.toString().padLeft(2, '0')}";
      final end =
          "${range.end.year}-${range.end.month.toString().padLeft(2, '0')}-${range.end.day.toString().padLeft(2, '0')}";
      url += "?startDate=$start&endDate=$end";
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final students = data["students"];
        final totalClasses = data["totalDays"];

        String monthYear = range != null
            ? DateFormat('MMMM yyyy').format(range.start)
            : DateFormat('MMMM yyyy').format(DateTime.now());

        if (type == "excel") {
          String csv = "";
          csv += "Class: $className\n";
          csv += "Month: $monthYear\n";
          csv += "Total Classes: $totalClasses\n\n";
          csv += "S.Rn,Roll No,Student Name,Present,Percentage\n";

          for (int i = 0; i < students.length; i++) {
            final s = students[i];
            csv +=
            "${i + 1},${s["rollNo"]},${s["name"]},${s["present"]},${s["percentage"]}%\n";
          }

          final dir = await getApplicationDocumentsDirectory();
          final filePath = "${dir.path}/attendance_$className.csv";
          final file = File(filePath);
          await file.writeAsString(csv);
          await OpenFilex.open(filePath);
        }

        if (type == "pdf") {
          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              build: (context) => [
                pw.Text(
                  "Attendance Report",
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Class: $className"),
                pw.Text("Month: $monthYear"),
                pw.Text("Total Classes: $totalClasses"),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ["S.Rn", "Roll No", "Name", "Present", "Percentage"],
                  data: List.generate(students.length, (i) {
                    final s = students[i];
                    return [
                      "${i + 1}",
                      s["rollNo"],
                      s["name"],
                      "${s["present"]}",
                      "${s["percentage"]}%"
                    ];
                  }),
                ),
              ],
            ),
          );
          await Printing.layoutPdf(
            onLayout: (format) async => pdf.save(),
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == "excel"
                  ? "Excel downloaded successfully"
                  : "PDF ready to view",
            ),
            backgroundColor: const Color(0xFF00A76F),
          ),
        );
      } else {
        throw Exception("Download failed");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error downloading file"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading.remove(key));
      }
    }
  }

  Future<void> _pickDateRange(int index) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _customRanges[index] ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A76F),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _customRanges[index] = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = getToken();
      if (token.isNotEmpty) {
        context.read<TeacherClassBloc>().add(TeacherFetchClasses(token));
      }
    });
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          Header(
            heading: 'Download Attendance',
            subheading: 'Export attendance records',
          ),
          Expanded(
            child: BlocBuilder<TeacherClassBloc, TeacherClassState>(
              builder: (context, state) {
                if (state is TeacherClassLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00A76F),
                    ),
                  );
                }

                if (state is TeacherClassError) {
                  return Center(
                    child: Text(
                      "Error: ${state.message}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state is TeacherClassLoaded) {
                  if (state.classes.isEmpty) {
                    return const Center(
                      child: Text(
                        "No classes found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: state.classes.length,
                    itemBuilder: (context, index) {
                      final cls = state.classes[index];
                      const accent = Color(0xFF00A76F);
                      final iconBg = accent.withOpacity(0.14);
                      final range = _customRanges[index];
                      final isPdfLoading = _isDownloading(index, 'pdf');
                      final isExcelLoading = _isDownloading(index, 'excel');
                      final isAnyLoading = isPdfLoading || isExcelLoading;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == state.classes.length - 1 ? 0 : 16,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Class Info Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: accent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cls.className,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${cls.students.length} students',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Download Progress Bar
                              if (isAnyLoading) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FBF6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF00A76F)
                                            .withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF00A76F),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            isPdfLoading
                                                ? 'Generating PDF...'
                                                : 'Generating Excel...',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF00A76F),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          minHeight: 5,
                                          backgroundColor: const Color(
                                              0xFF00A76F)
                                              .withOpacity(0.15),
                                          color: const Color(0xFF00A76F),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Please wait, preparing your file...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),

                              // Selected Date Range Display
                              if (range != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFBFD7FF)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.date_range,
                                          color: Color(0xFF2563EB), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_formatDate(range.start)}  →  ${_formatDate(range.end)}',
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _customRanges.remove(index);
                                          });
                                        },
                                        child: const Icon(Icons.close,
                                            color: Color(0xFF2563EB),
                                            size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // PDF + Excel Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPdfLoading
                                              ? const Color(0xFFFF1744)
                                              .withOpacity(0.5)
                                              : const Color(0xFFFF1744),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: isAnyLoading
                                            ? null
                                            : () => downloadAttendance(
                                          classCode: cls.classCode,
                                          className: cls.className,
                                          index: index,
                                          range: _customRanges[index],
                                          type: 'pdf',
                                        ),
                                        icon: isPdfLoading
                                            ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : const Icon(
                                            Icons.picture_as_pdf_outlined,
                                            size: 20),
                                        label: Text(
                                          isPdfLoading ? 'Loading...' : 'PDF',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isExcelLoading
                                              ? const Color(0xFF00A76F)
                                              .withOpacity(0.5)
                                              : const Color(0xFF00A76F),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: isAnyLoading
                                            ? null
                                            : () => downloadAttendance(
                                          classCode: cls.classCode,
                                          className: cls.className,
                                          index: index,
                                          range: _customRanges[index],
                                          type: 'excel',
                                        ),
                                        icon: isExcelLoading
                                            ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : const Icon(
                                            Icons.table_chart_outlined,
                                            size: 20),
                                        label: Text(
                                          isExcelLoading
                                              ? 'Loading...'
                                              : 'Excel',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Custom Date Range Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFFBFD7FF), width: 1),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed:
                                  isAnyLoading ? null : () => _pickDateRange(index),
                                  icon: const Icon(Icons.filter_alt_outlined,
                                      color: Color(0xFF2563EB), size: 18),
                                  label: Text(
                                    range == null
                                        ? 'Custom Date Range'
                                        : 'Change Date Range',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
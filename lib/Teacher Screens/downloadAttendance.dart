import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';

class DownloadAttendancePage extends StatefulWidget {
  @override
  _DownloadAttendancePageState createState() => _DownloadAttendancePageState();
}

class _DownloadAttendancePageState extends State<DownloadAttendancePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<Map<String, String>> classList = [];
  String selectedMonth = 'All Months';
  bool isLoading = false;

  double downloadProgress = 0.0;
  bool isDownloading = false;

  final monthMap = {
    "January": "01",
    "February": "02",
    "March": "03",
    "April": "04",
    "May": "05",
    "June": "06",
    "July": "07",
    "August": "08",
    "September": "09",
    "October": "10",
    "November": "11",
    "December": "12",
  };

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    setState(() => isLoading = true);
    final user = auth.currentUser;
    if (user == null) return;

    final snapshot = await firestore
        .collection("classes")
        .where("createdBy", isEqualTo: user.uid)
        .get();

    List<Map<String, String>> tempList = [];

    for (var doc in snapshot.docs) {
      final code = doc['code'].toString();
      final title = doc['name'].toString();
      // compute students count and attendance percent
      final students = List<String>.from(doc.data().containsKey('students') ? (doc['students'] ?? []) : []);
      int studentsCount = students.length;

      double classPercent = 0.0;
      try {
        final attendanceDoc = await firestore
            .collection("Attendance")
            .doc(code)
            .collection("DateList")
            .doc("AllDates")
            .get();
        final allDates = List<String>.from(attendanceDoc.data()?['dates'] ?? []);
        if (allDates.isNotEmpty && studentsCount > 0) {
          int totalPresent = 0;
          int totalPossible = 0;
          for (String date in allDates) {
            final snaps = await firestore.collection("Attendance").doc(code).collection(date).get();
            int presentOnDate = 0;
            for (var sdoc in snaps.docs) {
              if (sdoc.id == "FinalSubmit") continue;
              final status = sdoc.data()['status']?.toString() ?? 'Absent';
              if (status == 'Present') presentOnDate++;
            }
            totalPresent += presentOnDate;
            totalPossible += studentsCount;
          }
          classPercent = totalPossible == 0 ? 0.0 : (totalPresent * 100) / totalPossible;
        }
      } catch (_) {
        classPercent = 0.0;
      }

      tempList.add({
        'title': title,
        'code': code,
        'studentsCount': studentsCount.toString(),
        'attendancePercent': classPercent.round().toString(),
        'active': 'true',
      });
    }

    setState(() {
      classList = tempList;
      isLoading = false;
    });
  }

  String? selectedFormat; // 'pdf' or 'excel'
  DateTime? fromDate;
  DateTime? toDate;

  void showDownloadFormDialog(String classCode, String className) {
    selectedFormat = null;
    fromDate = null;
    toDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient background and rounded top
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                    child: Row(
                      children: const [
                        Icon(Icons.download_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text('Download Attendance',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Format selector
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF3FBF8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "Select Format",
                              prefixIcon: Icon(Icons.insert_drive_file_rounded, color: Color(0xFF2563EB)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            value: selectedFormat,
                            items: [
                              DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                              DropdownMenuItem(value: 'excel', child: Text('Excel')),
                            ],
                            onChanged: (val) => setState(() => selectedFormat = val),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Date pickers
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF3FBF8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: fromDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) setState(() => fromDate = picked);
                                  },
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: "From Date",
                                        prefixIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB)),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      controller: TextEditingController(
                                        text: fromDate != null
                                            ? "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}"
                                            : "",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: toDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) setState(() => toDate = picked);
                                  },
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: "To Date",
                                        prefixIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB)),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      controller: TextEditingController(
                                        text: toDate != null
                                            ? "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}"
                                            : "",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                label: Text('Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: selectedFormat != null
                                    ? () {
                                        Navigator.pop(context);
                                        _downloadWithDialog(
                                          classCode,
                                          className,
                                          isPdf: selectedFormat == 'pdf',
                                          from: fromDate,
                                          to: toDate,
                                        );
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadWithDialog(
    String classCode,
    String className, {
    required bool isPdf,
    DateTime? from,
    DateTime? to,
  }) async {
    setState(() {
      isLoading = true;
      isDownloading = true;
      downloadProgress = 0.0;
    });
    try {
      final attendanceDoc = await firestore
          .collection("Attendance")
          .doc(classCode)
          .collection("DateList")
          .doc("AllDates")
          .get();

      final allDates = List<String>.from(attendanceDoc['dates'] ?? []);
      List<String> filteredDates = allDates;

      if (from != null && to != null) {
        filteredDates = filteredDates.where((d) {
          final date = DateTime.parse(d);
          return !date.isBefore(from) && !date.isAfter(to);
        }).toList();
      }

      Map<String, Pair<int, int>> attendanceMap = {};
      int totalDates = filteredDates.length;
      int processedDates = 0;

      for (String date in filteredDates) {
        final snapshots = await firestore
            .collection("Attendance")
            .doc(classCode)
            .collection(date)
            .get();

        for (var doc in snapshots.docs) {
          if (doc.id == "FinalSubmit") continue;
          if (!doc.data().containsKey('status')) continue;

          String id = doc.id;
          String status = doc['status'];
          var entry = attendanceMap[id] ?? Pair(0, 0);
          if (status == "Present") {
            attendanceMap[id] = Pair(entry.first + 1, entry.second);
          } else {
            attendanceMap[id] = Pair(entry.first, entry.second + 1);
          }
        }
        processedDates++;
        setState(() {
          downloadProgress = totalDates == 0 ? 0.0 : processedDates / totalDates;
        });
      }

      final List<Map<String, dynamic>> finalData = [];
      for (var entry in attendanceMap.entries) {
        final userDoc =
            await firestore.collection("students").doc(entry.key).get();
        String name = userDoc['name'] ?? 'Unknown';
        String roll = userDoc['roll'] ?? 'N/A';
        int present = entry.value.first;
        int absent = entry.value.second;
        int total = present + absent;
        double percent = total == 0 ? 0.0 : (present * 100) / total;

        finalData.add({
          'name': name,
          'roll': roll,
          'present': present,
          'absent': absent,
          'percent': percent,
        });
      }
      finalData.sort((a, b) => a['roll'].compareTo(b['roll']));

      if (isPdf) {
        await generatePdf(finalData, className);
      } else {
        await generateExcel(finalData, className);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${e.toString()}")));
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
        downloadProgress = 0.0;
      });
    }
  }

  Future<void> generatePdf(
      List<Map<String, dynamic>> data, String className) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text("Attendance Report - $className",
                style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Name', 'Roll No', 'Present', 'Absent', '%'],
              data: data.map((e) {
                return [
                  e['name'],
                  e['roll'],
                  e['present'].toString(),
                  e['absent'].toString(),
                  e['percent'].toStringAsFixed(2)
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/Attendance_$className.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  Future<void> generateExcel(
      List<Map<String, dynamic>> data, String className) async {
    var excel = Excel.createExcel();
    final String sheetName = 'Attendance';
    Sheet sheetObject = excel[sheetName] ?? excel[excel.getDefaultSheet()!]!;
    excel.setDefaultSheet(sheetName);

    // Append headers
    sheetObject.appendRow(["Name", "Roll No", "Present", "Absent", "Percentage"]);

    // Append data
    for (var row in data) {
      sheetObject.appendRow([
        row['name'],
        row['roll'],
        row['present'],
        row['absent'],
        row['percent'].toStringAsFixed(2),
      ]);
    }

    final Directory? dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception("Could not access storage directory");
    }

    final String path = '${dir.path}/Attendance_$className.xlsx';
    final File file = File(path);

    
    final List<int>? fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception("Excel encoding failed.");
    }

    await file.writeAsBytes(fileBytes, flush: true);
    await OpenFile.open(file.path);
  }


  Widget shimmerClassList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 3,
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Avatar shimmer
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title shimmer
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade100],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle shimmer
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade200, Colors.grey.shade100],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Button shimmer
                    Container(
                      height: 32,
                      width: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade100],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget downloadInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Color(0xFFF1F8FE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.download_rounded, color: Color(0xff0A80F5), size: 22),
              SizedBox(width: 8),
              Text('Download Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text('• PDF format is best for printing and official records', style: TextStyle(fontSize: 14, color: Colors.black87)),
              ),
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text('• Excel format allows further data analysis and editing', style: TextStyle(fontSize: 14, color: Colors.black87)),
              ),
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text('• Custom date range lets you download specific time periods', style: TextStyle(fontSize: 14, color: Colors.black87)),
              ),
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('• Downloaded files include student names, dates, and attendance status', style: TextStyle(fontSize: 14, color: Colors.black87)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF8),
      body: Stack(
        children: [
          Column(
            children: [
              // Header with gradient and rounded bottom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40,bottom: 24, left: 24, right: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SizedBox(height: 2),
                          Text('Download Attendance',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),

                          Text('Export attendance records',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // Show shimmer if loading, else show class list
              isLoading
                  ? Expanded(child: shimmerClassList())
                  : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: classList.length + 1,
                      itemBuilder: (_, index) {
                        if (index < classList.length) {
                          final item = classList[index];
                          final studentsCount = item['studentsCount'] ?? '0';
                          final attendancePercent = item['attendancePercent'] ?? '0';
                          final active = item['active'] == 'true';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0,2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6FAF0),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF10B981)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text('$studentsCount students · $attendancePercent% attendance', style: TextStyle(color: Colors.grey[600])),
                                                const SizedBox(width: 8),
                                                if (active)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEFFCF3),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: const Text('Active', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () => showDownloadFormDialog(item['code']!, item['title']!),
                                            icon: const Icon(Icons.download_rounded, color: Colors.white),
                                            label: const Text('Download'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // Last item: download info card
                          return downloadInfoCard();
                        }
                      },
                    ),
                  ),
            ],
          ),
          if (isDownloading)
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.download_rounded, color: Color(0xff0A80F5), size: 26),
                        SizedBox(width: 12),
                        Text('Downloading Attendance...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      value: downloadProgress,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE0E7EF),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xff0A80F5)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 15, color: Color(0xff0A80F5), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Pair<F, S> {
  F first;
  S second;

  Pair(this.first, this.second);
}

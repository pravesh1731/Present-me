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

    setState(() {
      classList = snapshot.docs.map((doc) {
        return {
          'title': doc['name'].toString(),
          'code': doc['code'].toString(),
        };
      }).toList();
      isLoading = false;
    });
  }

  void showFormatDialog(String classCode, String className) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Choose Format'),
        actions: [
          TextButton(
              onPressed: () => _download(classCode, className, isPdf: true),
              child: Text('PDF')),
          TextButton(
              onPressed: () => _download(classCode, className, isPdf: false),
              child: Text('Excel')),
        ],
      ),
    );
  }

  Future<void> _download(String classCode, String className,
      {required bool isPdf}) async {
    Navigator.pop(context);

    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Storage permission is required.")));
          return;
        }
      }
    }

    setState(() => isLoading = true);
    try {
      final attendanceDoc = await firestore
          .collection("Attendance")
          .doc(classCode)
          .collection("DateList")
          .doc("AllDates")
          .get();

      final allDates = List<String>.from(attendanceDoc['dates'] ?? []);
      final filteredDates = selectedMonth == "All Months"
          ? allDates
          : allDates
          .where((d) => d.substring(4, 6) == monthMap[selectedMonth])
          .toList();

      Map<String, Pair<int, int>> attendanceMap = {};
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
      setState(() => isLoading = false);
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

    // Important: encode and check if it's not null
    final List<int>? fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception("Excel encoding failed.");
    }

    await file.writeAsBytes(fileBytes, flush: true);
    await OpenFile.open(file.path);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Download Attendance',style: TextStyle(fontSize: 22, color: Colors.white),),
          flexibleSpace: Container(
          decoration: const BoxDecoration(
          gradient: LinearGradient(
          colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
    )
    ),),

      body:

      isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24,left: 12,right: 12, bottom: 24),
            child: DropdownButtonFormField<String>(
              value: selectedMonth,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Month",
              ),
              items: ['All Months', ...monthMap.keys]
                  .map((e) => DropdownMenuItem(
                child: Text(e),
                value: e,
              ))
                  .toList(),
              onChanged: (value) => setState(() {
                selectedMonth = value!;
              }),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: classList.length,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (_, index) {
                final item = classList[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.pink, width: 1),
                  ),
                  elevation: 4,
                  shadowColor: Colors.pink,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Code: ${item['code']}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => showFormatDialog(item['code']!, item['title']!),
                          icon: Icon(Icons.download_rounded, color: Colors.white),
                          label: Text(
                            "Download",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            backgroundColor: Colors.lightBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )

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

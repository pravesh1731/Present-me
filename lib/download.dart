import 'dart:io';
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
      appBar: AppBar(title: Text('Download Attendance')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
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
              itemBuilder: (_, index) {
                final item = classList[index];
                return ListTile(
                  title: Text(item['title'] ?? ''),
                  subtitle: Text("Code: ${item['code']}"),
                  trailing: ElevatedButton(
                    child: Text("Download"),
                    onPressed: () => showFormatDialog(
                        item['code']!, item['title']!),
                  ),
                );
              },
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

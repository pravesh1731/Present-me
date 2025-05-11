import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class student_Attendance_Details extends StatelessWidget{

  final String studentName = 'Pravesh Chaudhary';
  final String rollNo = '23036245';
  final int presentCount = 40;
  final int absentCount = 10;

  final List<Map<String, String>> attendanceData = [
    {'date': '03-05-2025', 'status': 'Present'},
    {'date': '02-05-2025', 'status': 'Present'},
    {'date': '30-04-2025', 'status': 'Absent'},
    {'date': '28-04-2025', 'status': 'Absent'},
    {'date': '26-04-2025', 'status': 'Present'},
    {'date': '25-04-2025', 'status': 'Present'},
    {'date': '24-04-2025', 'status': 'Present'},
    {'date': '23-04-2025', 'status': 'Present'},
    {'date': '22-04-2025', 'status': 'Present'},
  ];

  @override
  Widget build(BuildContext context) {

    int presentCount = attendanceData.where((e) => e['status'] == 'Present').length;
    int total = attendanceData.length;
    int absentCount = total - presentCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Attendance' ,style:TextStyle(fontSize: 24, color: Colors.white) ,),
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
            )
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
              ),
              child: Column(
                children: [
                  SizedBox(height: 2),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60),
                  ),
                  SizedBox(height: 8),
                  Text(
                    studentName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    rollNo,
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),

            // Pie chart and totals
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shadowColor: Colors.red.shade300,
                color: Colors.lightBlue.shade50,
                child: Column(
                
                  children: [
                
                    Text("Total: $total      Present: $presentCount      Absent: $absentCount"),
                    SizedBox(height: 10),
                    PieChart(
                      dataMap: {
                        "Present": presentCount.toDouble(),
                        "Absent": absentCount.toDouble(),
                      },
                      chartType: ChartType.disc,
                      chartRadius: 120,
                      animationDuration: Duration(milliseconds: 800),
                      colorList: [Colors.green, Colors.redAccent],
                      chartValuesOptions: ChartValuesOptions(
                        showChartValuesInPercentage: true,
                        showChartValuesOutside: true,
                        decimalPlaces: 0,
                      ),
                      legendOptions: LegendOptions(
                        showLegends: true,
                        legendPosition: LegendPosition.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Attendance list
            Expanded(
              child: ListView.builder(
                itemCount: attendanceData.length,
                itemBuilder: (context, index) {
                  final item = attendanceData[index];
                  final isPresent = item['status'] == 'Present';

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isPresent ? Colors.green : Colors.red),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['date']!,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(
                              isPresent ? Icons.check_circle : Icons.cancel,
                              color: isPresent ? Colors.green : Colors.red,
                            ),
                            SizedBox(width: 6),
                            Text(item['status']!),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
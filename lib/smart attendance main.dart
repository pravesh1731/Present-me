import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'button.dart';

class smartAttendanceMain extends StatelessWidget{

  final String className = "Python 4th Semester";
  final String classCode = "b39747";
  final String hotspotName = "moto_G54";

  final List<Map<String, String>> presentStudents = List.generate(
    11,
        (index) => {
      'name': 'Pravesh Chaudhary',
      'roll': '23036245',
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text('Smart Attendance' ,style:TextStyle(fontSize: 22, color: Colors.white) ,),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Info Box
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class Name : $className', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Class Code : $classCode'),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Hotspot Name:", style: TextStyle(fontWeight: FontWeight.bold),),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "hotspot name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.center,
                      child: Button(text: "Enable Hotspot", onPressed: (){}))
                ],
              ),
            ),
            SizedBox(height: 20),

            // Present Students Grid
            Text('Present Students : ${presentStudents.length}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: presentStudents.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final student = presentStudents[index];
                  return Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.person, size: 28, color: Colors.blue),
                        ),
                        SizedBox(height: 10),
                        Text(student['name']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(student['roll']!, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
          margin: EdgeInsets.only(bottom: 24 ,left:16,right: 16,top: 8 ),
          child: Button(text: "Enable Attendance", onPressed: (){})),
    );
  }

}
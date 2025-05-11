import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/student%20attendance%20Details.dart';

class track_Student_List_Classes extends StatelessWidget{

  final List<Map<String, String>> students = [
    {'name': 'Pravesh Chaudhary', 'roll': '23036245'},
    {'name': 'Amit Verma', 'roll': '23036246'},
    {'name': 'Sneha Yadav', 'roll': '23036247'},
    {'name': 'Ravi Kumar', 'roll': '23036248'},
    {'name': 'Ram Kumar', 'roll': '23036248'},
    {'name': 'Ravi Kumar', 'roll': '23036248'},
    {'name': 'Ravi Kumar', 'roll': '23036248'},
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
       title: Column(
         children: [
           Text('Class Name' ,style:TextStyle(fontSize: 22, color: Colors.white) ,),
           Text('Class Code' ,style:TextStyle(fontSize: 16, color: Colors.white) ,),
         ],
       ),
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
            // Students list
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return InkWell(
                    onTap: (){
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 500), // Adjust speed here
                          pageBuilder: (_, __, ___) => student_Attendance_Details(),
                          transitionsBuilder: (_, animation, __, child) {
                            const begin = Offset(1.0, 0.0); // Slide from right
                            const end = Offset.zero;
                            const curve = Curves.easeInOutBack;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width:3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.person, color: Colors.blue),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student['name']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Roll No: ${student['roll']}'),
                              ],
                            ),
                          ),

                        ],
                      ),
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
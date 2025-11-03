 import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/manual%20attendance%20classes%20screen.dart';
import 'package:present_me_flutter/smart%20attendance%20classes.dart';

class takeAttendnace extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance' ,style:TextStyle(fontSize: 24, color: Colors.white) ,),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              onTap: (){
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500), // Adjust speed here
                    pageBuilder: (_, __, ___) => ManualAttendanceClasses(),
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
              child: SizedBox(
                height: 300,
                width: 500,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 3), // Border color & width
                    borderRadius: BorderRadius.circular(16),          // Match Card radius
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset("assets/image/manual.png"),
                      ),
                      Text('Manual Attendance', style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                      Text(
                        ' Manually mark attendance by profile',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04, // 4% of screen width
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        
            InkWell(
              onTap: (){
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500), // Adjust speed here
                    pageBuilder: (_, __, ___) => SmartAttendanceClasses(),
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
              child: SizedBox(
                height: 300,
                width: 500,
                child: Container(
                  margin: const EdgeInsets.only(top: 8,bottom: 24, left: 24, right: 24),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 3), // Border color & width
                    borderRadius: BorderRadius.circular(16),          // Match Card radius
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Image.asset("assets/image/smart.png"),
                      ),
                      Text('Smart Attendance', style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                      Text(
                        'Use smart detection to mark attendance',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04, // 4% of screen width
                        ),
                        textAlign: TextAlign.center,
                      ),


                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
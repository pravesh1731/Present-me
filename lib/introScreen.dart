import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/button.dart';
import 'package:present_me_flutter/student%20login%20screen.dart';
import 'package:present_me_flutter/teacher%20login%20screen.dart';

class introscreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 70.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Attendance', style: TextStyle(fontSize: 40 ,color: Color(0xff1E90FF)),),
                SizedBox(height: 8),
                Text('Lets Get Started', style: TextStyle(fontSize: 22 ,color: Colors.black,fontWeight: FontWeight.bold),),
                SizedBox(height: 8),
                Text('Check Your attendance Daily!', style: TextStyle(fontSize: 16 ,color: Colors.black),),
                SizedBox(height: 50),

                SizedBox(
                  height:   150,
                    width: 150,
                    child: Image.asset("assets/image/teacher.png")),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: 170,
                      child: Button(text: 'TEACHER',borderRadius: 20, onPressed: (){
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 600), 
                            pageBuilder: (_, __, ___) => teacherLogin(),
                            transitionsBuilder: (_, animation, __, child) {
                              const begin = Offset(1.0, 0.0); 
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
                        ;
                      },)
                  ),
                ),
                 SizedBox(
                    height: 165,
                    width: 165,
                    child: Image.asset("assets/image/studnet.png")),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 170,
                      child: Button(text: 'STUDENT',borderRadius: 20,onPressed: (){
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 600), 
                            pageBuilder: (_, __, ___) => studentlogin(),
                            transitionsBuilder: (_, animation, __, child) {
                              const begin = Offset(1.0, 0.0); 
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
                        ;
                      },
                      ),

                ),
                ),
              ],
            ),
          ),
      ),
      )
    );
  }

}


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/button.dart';

import 'otpVerified screen.dart';

class otpVerify extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors:
              [Color(0xff0BCCEB),Color(0xff0A80F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 90),
                Logo(),
                const Text('OTP Verification',style: TextStyle(
                  fontSize: 35,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),),
                SizedBox(height: 8,),
                Center(
                  child: Card(
                    margin: EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    shadowColor: Colors.grey,
                    elevation: 32,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Code send to 700458210. "
                                "This code will expire in "
                                "01:30s",
                            style: TextStyle(fontSize: 18,),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              return SizedBox(
                                width: 55,
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    counterText: "", // hides character counter
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onChanged: (value) {

                                    if (value.length == 1 && index < 3) {
                                      FocusScope.of(context).nextFocus();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 16,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Text("Resend" , style: TextStyle(fontSize: 18,color: Colors.blue),),
                              const Text("00:45" , style: TextStyle(fontSize: 18,color: Colors.blue),),
                            ],
                          )

                        ],

                      ),

                  ),
                )
                ),
                Center(
                    child: Card(
                      margin: EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      shadowColor: Colors.grey,
                      elevation: 32,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Code send to abc@gmail.com. "
                                  "This code will expire in "
                                  "01:30s",
                              style: TextStyle(fontSize: 18,),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) {
                                return SizedBox(
                                  width: 55,
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      counterText: "", // hides character counter
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onChanged: (value) {

                                      if (value.length == 1 && index < 3) {
                                        FocusScope.of(context).nextFocus();
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: 16,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                const Text("Resend" , style: TextStyle(fontSize: 18,color: Colors.blue),),
                                const Text("00:45" , style: TextStyle(fontSize: 18,color: Colors.blue),),
                              ],
                            )

                          ],

                        ),

                      ),
                    )
                ),
                SizedBox(height: 20,),
                SizedBox(
                  width: 380,
                    child: Button1(text: 'Verify', icon: Icon(Icons.verified), onPressed: (){
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 600), // Adjust speed here
                          pageBuilder: (_, __, ___) => otpVerified(),
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
                    })
                ),

              ],
            ),

        ),
        ),
      ),
    );
  }

}
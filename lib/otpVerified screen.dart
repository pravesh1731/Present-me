import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'button.dart';

class otpVerified extends StatelessWidget{
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
                const Text('Verification Successful',style: TextStyle(
                  fontSize: 35,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),),
                SizedBox(height: 24,),
                    
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Congrats!' ,style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),),
                  ),
                ),
                SizedBox(height: 16,),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Text('Your mobile and gmail OTP verification is successful.Your Account is created successfully.' ,style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    
                  ),
                  ),
                ),
                SizedBox(height: 100,),
                SizedBox(
                  child: FaIcon(FontAwesomeIcons.circleCheck, size: 100.0,color: Colors.white,),
                ),
                SizedBox(height: 220,),
                    
                Container(
                    
                    
                    padding: EdgeInsets.only(left: 30, right: 30,bottom: 30),
                    child: Align(child: Button1(text: 'Continue', icon: Icon(Icons.check), onPressed: (){},))),
              ],
            ),
          ),
        ),
      ),

    );
  }

}
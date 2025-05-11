import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/button.dart';
import 'package:present_me_flutter/teacher%20login%20screen.dart';

class teacher_Profile extends StatefulWidget{
  @override
  State<teacher_Profile> createState() => _teacher_ProfileState();
}

class _teacher_ProfileState extends State<teacher_Profile> {
  bool isEditing = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final hotspotController = TextEditingController();
  final designationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
       title: Text('Profile' ,style:TextStyle(fontSize: 24, color: Colors.white) ,),
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
      body: Column(
        children: [

          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() => isEditing = !isEditing);
                  },
                  child:
                  Text(isEditing ? 'Cancel Edit' : 'Edit Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    buildTextField("Name", nameController),
                    buildTextField("Email", emailController),
                    buildTextField("Mobile", mobileController),
                    buildTextField("Hotspot Name", hotspotController),
                    buildTextField("Designation", designationController),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: Button(text: 'Save Changes', onPressed: (){

                      }),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // You can adjust the radius
                          ),
                        ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();

                            if (!mounted) return;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => teacherLogin()),
                                  (Route<dynamic> route) => false, // Remove all previous routes
                            );
                          },


                        child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: isEditing ? Colors.white : Colors.grey.shade200,
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String roll;
  final DateTime createdAt;
  final String role;

  Student({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.roll,
    required this.createdAt,
    this.role = 'student',  // Default value set to 'student'
  });

  // Convert a Student object into a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'roll': roll,
      'createdAt': createdAt.toIso8601String(),
      'role': role,  // role will always be 'student'
    };
  }

  // Create a Student object from a Firestore document map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      roll: map['roll'],
      createdAt: DateTime.parse(map['createdAt']),
      role: map['role'],
    );
  }

  // Convert a Firestore document snapshot into a Student object
  factory Student.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      roll: data['roll'],
      createdAt: DateTime.parse(data['createdAt']),
      role: data['role'],
    );
  }
}

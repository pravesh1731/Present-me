class Teacher {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String hotspot;
  final DateTime createdAt;
  final String role; // NEW FIELD

  Teacher({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.hotspot,
    required this.createdAt,
    this.role = 'teacher', // Default value set
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'hotspot': hotspot,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      hotspot: map['hotspot'],
      createdAt: DateTime.parse(map['createdAt']),
      role: map['role'] ?? 'teacher', // Fallback to 'teacher' if missing
    );
  }
}

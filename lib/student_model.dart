class Student {
  final String studentId;
  final String firstName;
  final String lastName;
  final String emailId;
  final String phone;
  final String rollNo;
  final String semester;
  final String branch;
  final String year;
  final String section;
  final String profilePicUrl;
  final String institutionId;
  final String createdAt;

  Student({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.emailId,
    required this.phone,
    required this.rollNo,
    required this.semester,
    required this.branch,
    required this.year,
    required this.section,
    required this.profilePicUrl,
    required this.institutionId,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['studentId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      emailId: json['emailId'] ?? '',
      phone: json['phone'] ?? '',
      rollNo: json['rollNo'] ?? '',
      semester: json['semester'] ?? '',
      branch: json['branch'] ?? '',
      year: json['year'] ?? '',
      section: json['section'] ?? '',
      profilePicUrl: json['profilePicUrl'] ?? '',
      institutionId: json['institutionId'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'firstName': firstName,
      'lastName': lastName,
      'emailId': emailId,
      'phone': phone,
      'rollNo': rollNo,
      'semester': semester,
      'branch': branch,
      'year': year,
      'section': section,
      'profilePicUrl': profilePicUrl,
      'institutionId': institutionId,
      'createdAt': createdAt,
    };
  }
}

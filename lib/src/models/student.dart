class Student {
  final String studentId;
  final String emailId;
  final String firstName;
  final String lastName;
  final String phone;
  final String rollNo;

  final String semester;
  final String branch;
  final String year;
  final String section;

  final String profilePicUrl;

  final String createdAt;

  Student({
    required this.studentId,
    required this.emailId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.rollNo,
    required this.semester,
    required this.branch,
    required this.year,
    required this.section,
    required this.profilePicUrl,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json["studentId"] ?? "",
      emailId: json["emailId"] ?? "",
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      phone: json["phone"] ?? "",
      rollNo: json["rollNo"] ?? "",
      semester: json["semester"] ?? "",
      branch: json["branch"] ?? "",
      year: json["year"] ?? "",
      section: json["section"] ?? "",
      profilePicUrl: json["profilePicUrl"] ?? "",
      createdAt: json["createdAt"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "studentId": studentId,
      "emailId": emailId,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "rollNo": rollNo,
      "semester": semester,
      "branch": branch,
      "year": year,
      "section": section,
      "profilePicUrl": profilePicUrl,
      "createdAt": createdAt,
    };
  }

  Student copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? semester,
    String? branch,
    String? year,
    String? section,
    String? profilePicUrl,
  }) {
    return Student(
      studentId: studentId,
      emailId: emailId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      rollNo: rollNo,
      semester: semester ?? this.semester,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      section: section ?? this.section,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      createdAt: createdAt,
    );
  }
}


class Teacher {
  final String teacherId;
  final String emailId;
  final String firstName;
  final String lastName;
  final String phone;
  final String hotspotName;
  final String officeLocation;
  final String department;
  final String specialization;
  final String qualification;
  final String experience;
  final String empId;
  
  final String profilePicUrl;
  final String createdAt;

  Teacher({
    required this.teacherId,
    required this.emailId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.hotspotName,
    required this.officeLocation,
    required this.department,
    required this.specialization,
    required this.qualification,
    required this.experience,
    required this.empId,
    required this.profilePicUrl,
    required this.createdAt,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      teacherId: json["teacherId"] ?? "",
      emailId: json["emailId"] ?? "",
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      phone: json["phone"] ?? "",
      hotspotName: json["hotspotName"] ?? "",
      officeLocation: json["officeLocation"] ?? "",
      department: json["department"] ?? "",
      specialization: json["specialization"] ?? "",
      qualification: json["qualification"] ?? "",
      experience: json["experience"] ?? "",
      empId: json["empId"] ?? "",
      profilePicUrl: json["profilePicUrl"] ?? "",
      createdAt: json["createdAt"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "teacherId": teacherId,
      "emailId": emailId,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "hotspotName": hotspotName,
      "officeLocation": officeLocation,
      "department": department,
      "specialization": specialization,
      "qualification": qualification,
      "experience": experience,
      "empId": empId,
      "profilePicUrl": profilePicUrl,
      "createdAt": createdAt,
    };
  }

  Teacher copyWith({
    String? teacherId,
    String? emailId,
    String? firstName,
    String? lastName,
    String? phone,
    String? hotspotName,
    String? officeLocation,
    String? department,
    String? specialization,
    String? qualification,
    String? experience,
    String? empId,
    String? profilePicUrl,
    String? createdAt,
  }) {
    return Teacher(
      teacherId: teacherId ?? this.teacherId,
      emailId: emailId ?? this.emailId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      hotspotName: hotspotName ?? this.hotspotName,
      officeLocation: officeLocation ?? this.officeLocation,
      department: department ?? this.department,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      empId: empId ?? this.empId,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class College {
  final String id;
  final String name;

  College({required this.id, required this.name});

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'],
      name: json['name'],
    );
  }
}

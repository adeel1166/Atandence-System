
class School {
  String name;
  String id;
  String address;
  List schoolUsersRef; // reference to firebase uid

  School({
    required this.name,
    required this.id,
    required this.address,
    required this.schoolUsersRef
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'address': address,
      'schoolUsersRef': schoolUsersRef
    };
  }

  static School fromJson(Map<String, dynamic>? json) => School(
    name: json!['name'] ?? '',
    id: json['id'] ?? '',
    address: json['address'] ?? '',
    schoolUsersRef: json['schoolUsersRef'] ?? [],
  );
}

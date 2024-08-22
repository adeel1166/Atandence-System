
class Student {
  String name;
  String role;
  String subject;
  String phoneNo;
  DateTime date;
  String gender;
  bool isIn; // else is Out

  Student({
    required this.name,
    required this.role,
    required this.subject,
    required this.phoneNo,
    required this.date,
    required this.gender,
    required this.isIn});

  Map<String, dynamic> toJson() => {
    'name': name,
    'subject': subject,
    'phoneNo': phoneNo,
    'date': date,
    'gender': gender,
    'isIn': isIn,
  };

  static Student fromJson(Map<String, dynamic>? json) => Student(
      name: json!['name'] ?? '',
      role: json!['name'] ?? '',
      subject: json['subject'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      date: json['date'].toDate(),
      gender: json['gender'] ?? '',
      isIn: json['isIn'] ?? '',
  );

  @override
  bool operator ==(other) {
    return other is Student && name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}

class Staff {
  final String firstName;
  final String middleName;
  final String lastName;
  final String cellphoneNumber;

  Staff({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.cellphoneNumber, required String role,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'cellphoneNumber': cellphoneNumber,
  };
}

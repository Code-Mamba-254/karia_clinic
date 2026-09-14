class Doctor {
  final String id;
  final String fullName;
  final String email;
  final bool active;

  const Doctor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.active,
  });

  factory Doctor.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return Doctor(
      id: id,
      fullName: data["fullName"] ?? "",
      email: data["email"] ?? "",
      active: data["active"] ?? true,
    );
  }
}
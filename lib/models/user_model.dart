class UserModel {
  final String id;
  final String name;
  final String email;
  final bool approved;
  final bool isAdmin;
  final String? facePersonId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.approved,
    required this.isAdmin,
    this.facePersonId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      approved: json['approved'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      facePersonId: json['face_person_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'approved': approved,
      'is_admin': isAdmin,
      'face_person_id': facePersonId,
    };
  }
}
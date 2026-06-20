class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'admin' or 'user'
  final String status; // 'pending', 'approved', 'rejected'
  final bool faceRegistered;
  final List<double>? faceEmbedding;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.faceRegistered,
    this.faceEmbedding,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      role: map['role'] as String? ?? 'user',
      status: map['status'] as String? ?? 'pending',
      faceRegistered: map['face_registered'] as bool? ?? false,
      faceEmbedding: map['face_embedding'] != null 
          ? List<double>.from(map['face_embedding'] as List<dynamic>) 
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'status': status,
      'face_registered': faceRegistered,
      'face_embedding': faceEmbedding,
    };
  }
}
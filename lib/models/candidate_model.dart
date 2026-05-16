class CandidateModel {
  final String id;
  final String name;
  final String? description;
  final String pollId;
  final String? userId;

  CandidateModel({
    required this.id,
    required this.name,
    this.description,
    required this.pollId,
    this.userId,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    return CandidateModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      pollId: json['poll_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'poll_id': pollId,
      'user_id': userId,
    };
  }
}
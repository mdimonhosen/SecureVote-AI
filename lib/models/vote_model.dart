class VoteModel {
  final String id;
  final String userId;
  final String pollId;
  final String candidateId;
  final DateTime votedAt;

  VoteModel({
    required this.id,
    required this.userId,
    required this.pollId,
    required this.candidateId,
    required this.votedAt,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      id: json['id'],
      userId: json['user_id'],
      pollId: json['poll_id'],
      candidateId: json['candidate_id'],
      votedAt: DateTime.parse(json['voted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'poll_id': pollId,
      'candidate_id': candidateId,
      'voted_at': votedAt.toIso8601String(),
    };
  }
}
class CandidateModel {
  final String id;
  final String pollId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int voteCount;

  CandidateModel({
    required this.id,
    required this.pollId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.voteCount,
  });

  factory CandidateModel.fromMap(Map<String, dynamic> map) {
    return CandidateModel(
      id: map['id'] as String,
      pollId: map['poll_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      voteCount: map['vote_count'] as int? ?? 0,
    );
  }
}
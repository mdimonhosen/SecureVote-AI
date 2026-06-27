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
    this.voteCount = 0,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    return CandidateModel(
      id: json['id'],
      pollId: json['poll_id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      voteCount: json['vote_count'] ?? 0,
    );
  }

  // Added this specifically so poll_provider.dart stops crashing!
  factory CandidateModel.fromMap(Map<String, dynamic> map) {
    return CandidateModel.fromJson(map);
  }
}
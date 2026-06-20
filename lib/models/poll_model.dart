class PollModel {
  final String id;
  final String title;
  final String description;
  final bool isPrivate;
  final String? accessCode;
  final String? accessCodeHash;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;

  PollModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isPrivate,
    this.accessCode,
    this.accessCodeHash,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
  });

  factory PollModel.fromMap(Map<String, dynamic> map) {
    return PollModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isPrivate: map['is_private'] as bool? ?? false,
      accessCode: map['access_code'] as String?,
      accessCodeHash: map['access_code_hash'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      createdBy: map['created_by'] as String,
    );
  }

  // Helper to determine active status in the UI
  String get currentStatus {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'Upcoming';
    if (now.isAfter(endDate)) return 'Expired';
    return 'Current';
  }
}
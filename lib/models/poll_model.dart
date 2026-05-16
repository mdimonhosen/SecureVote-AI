import 'candidate_model.dart';

class PollModel {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPrivate;
  final String? securityCode;
  final String createdBy;
  final List<CandidateModel> candidates;

  PollModel({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.isPrivate,
    this.securityCode,
    required this.createdBy,
    required this.candidates,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isPrivate: json['is_private'] ?? false,
      securityCode: json['security_code'],
      createdBy: json['created_by'],
      candidates: (json['candidates'] as List<dynamic>?)
          ?.map((c) => CandidateModel.fromJson(c))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_private': isPrivate,
      'security_code': securityCode,
      'created_by': createdBy,
    };
  }

  bool get isActive => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isExpired => DateTime.now().isAfter(endDate);
}
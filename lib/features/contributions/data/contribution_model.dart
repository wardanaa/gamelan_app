enum ContributionStatus { draft, submitted, underReview, approved, rejected }

class ContributionModel {
  const ContributionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.knowledgeType,
    required this.gamelanType,
    required this.sourceNote,
    required this.contributorNote,
    required this.culturalSensitivity,
    required this.consentGiven,
    required this.createdAt,
    this.reviewNote,
  });

  final String id;
  final String title;
  final String description;
  final ContributionStatus status;
  final String knowledgeType;
  final String gamelanType;
  final String sourceNote;
  final String contributorNote;
  final bool culturalSensitivity;
  final bool consentGiven;
  final DateTime createdAt;
  final String? reviewNote;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'knowledgeType': knowledgeType,
      'gamelanType': gamelanType,
      'sourceNote': sourceNote,
      'contributorNote': contributorNote,
      'culturalSensitivity': culturalSensitivity,
      'consentGiven': consentGiven,
      'createdAt': createdAt.toIso8601String(),
      'reviewNote': reviewNote,
    };
  }

  static ContributionModel? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final title = json['title'];
    final description = json['description'];
    final statusName = json['status'];
    final knowledgeType = json['knowledgeType'];
    final gamelanType = json['gamelanType'];
    final sourceNote = json['sourceNote'];
    final contributorNote = json['contributorNote'];
    final culturalSensitivity = json['culturalSensitivity'];
    final consentGiven = json['consentGiven'];
    final createdAtValue = json['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;
    final status = statusName is String
        ? ContributionStatus.values
              .where((value) => value.name == statusName)
              .firstOrNull
        : null;

    if (id is! String ||
        title is! String ||
        description is! String ||
        status == null ||
        knowledgeType is! String ||
        gamelanType is! String ||
        sourceNote is! String ||
        contributorNote is! String ||
        culturalSensitivity is! bool ||
        consentGiven is! bool ||
        createdAt == null) {
      return null;
    }

    return ContributionModel(
      id: id,
      title: title,
      description: description,
      status: status,
      knowledgeType: knowledgeType,
      gamelanType: gamelanType,
      sourceNote: sourceNote,
      contributorNote: contributorNote,
      culturalSensitivity: culturalSensitivity,
      consentGiven: consentGiven,
      createdAt: createdAt,
      reviewNote: json['reviewNote'] is String
          ? json['reviewNote'] as String
          : null,
    );
  }

  ContributionModel copyWith({
    String? id,
    String? title,
    String? description,
    ContributionStatus? status,
    String? knowledgeType,
    String? gamelanType,
    String? sourceNote,
    String? contributorNote,
    bool? culturalSensitivity,
    bool? consentGiven,
    DateTime? createdAt,
    String? reviewNote,
  }) {
    return ContributionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      knowledgeType: knowledgeType ?? this.knowledgeType,
      gamelanType: gamelanType ?? this.gamelanType,
      sourceNote: sourceNote ?? this.sourceNote,
      contributorNote: contributorNote ?? this.contributorNote,
      culturalSensitivity: culturalSensitivity ?? this.culturalSensitivity,
      consentGiven: consentGiven ?? this.consentGiven,
      createdAt: createdAt ?? this.createdAt,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}

extension ContributionStatusLabel on ContributionStatus {
  String get label {
    return switch (this) {
      ContributionStatus.draft => 'Draft',
      ContributionStatus.submitted => 'Submitted',
      ContributionStatus.underReview => 'Under review',
      ContributionStatus.approved => 'Approved',
      ContributionStatus.rejected => 'Rejected',
    };
  }
}

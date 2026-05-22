import '../../../core/api/api_parsers.dart';
import '../../../core/mapping/taxonomy_mapper.dart';

enum ContributionStatus {
  draft,
  submitted,
  needsRevision,
  underReview,
  curatorApproved,
  expertRequired,
  expertApproved,
  published,
  rejected,
  archived;

  String get apiValue {
    return switch (this) {
      ContributionStatus.draft => 'draft',
      ContributionStatus.submitted => 'submitted',
      ContributionStatus.needsRevision => 'needs_revision',
      ContributionStatus.underReview => 'under_review',
      ContributionStatus.curatorApproved => 'curator_approved',
      ContributionStatus.expertRequired => 'expert_required',
      ContributionStatus.expertApproved => 'expert_approved',
      ContributionStatus.published => 'published',
      ContributionStatus.rejected => 'rejected',
      ContributionStatus.archived => 'archived',
    };
  }

  static ContributionStatus fromApiValue(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'draft' => ContributionStatus.draft,
      'submitted' => ContributionStatus.submitted,
      'needs_revision' => ContributionStatus.needsRevision,
      'under_review' => ContributionStatus.underReview,
      'curator_approved' => ContributionStatus.curatorApproved,
      'expert_required' => ContributionStatus.expertRequired,
      'expert_approved' => ContributionStatus.expertApproved,
      'published' => ContributionStatus.published,
      'rejected' => ContributionStatus.rejected,
      'archived' => ContributionStatus.archived,
      'approved' => ContributionStatus.curatorApproved,
      _ => ContributionStatus.submitted,
    };
  }
}

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
    this.contributionIntent,
    this.statusLabel,
    this.statusDescription,
    this.allowedActions = const [],
    this.updatedAt,
    this.reviewNote,
    this.knowledgeTypeSlug,
    this.gamelanTypeSlug,
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
  final String? contributionIntent;
  final String? statusLabel;
  final String? statusDescription;
  final List<String> allowedActions;
  final DateTime? updatedAt;
  final String? reviewNote;
  final String? knowledgeTypeSlug;
  final String? gamelanTypeSlug;

  bool get canEdit => allowedActions.contains('edit');
  bool get canSubmit => allowedActions.contains('submit');
  bool get canArchive => allowedActions.contains('archive');

  String get statusDisplayLabel => status.labelFor(this);

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.apiValue,
      'knowledgeType': knowledgeType,
      'gamelanType': gamelanType,
      'sourceNote': sourceNote,
      'contributorNote': contributorNote,
      'culturalSensitivity': culturalSensitivity,
      'consentGiven': consentGiven,
      'createdAt': createdAt.toIso8601String(),
      'contributionIntent': contributionIntent,
      'statusLabel': statusLabel,
      'statusDescription': statusDescription,
      'allowedActions': allowedActions,
      'updatedAt': updatedAt?.toIso8601String(),
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
        ? ContributionStatus.fromApiValue(statusName)
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
      contributionIntent: json['contributionIntent'] is String
          ? json['contributionIntent'] as String
          : null,
      statusLabel: json['statusLabel'] is String
          ? json['statusLabel'] as String
          : null,
      statusDescription: json['statusDescription'] is String
          ? json['statusDescription'] as String
          : null,
      allowedActions: stringListFrom(json, const ['allowedActions']),
      updatedAt: dateTimeFrom(json, const ['updatedAt']),
      reviewNote: json['reviewNote'] is String
          ? json['reviewNote'] as String
          : null,
    );
  }

  static ContributionModel? fromApi(
    Map<String, Object?> json, {
    TaxonomyMapper? taxonomy,
  }) {
    final mapper = taxonomy ?? TaxonomyMapper();
    final source = nestedObject(json, const ['contribution']) ?? json;
    final id = stringFrom(source, const ['id', 'uuid']);
    final title = stringFrom(source, const ['title']);
    final statusValue = stringFrom(source, const ['status']);
    final status = statusValue == null
        ? null
        : ContributionStatus.fromApiValue(statusValue);
    final knowledgeSlug = stringFrom(source, const ['knowledge_type']);
    final gamelanSlug = stringFrom(source, const ['gamelan_type']);
    final createdAt = dateTimeFrom(source, const ['created_at']);

    if (id == null || title == null || status == null || createdAt == null) {
      return null;
    }

    return ContributionModel(
      id: id,
      title: title,
      description: stringFrom(source, const ['description']) ?? '',
      status: status,
      knowledgeTypeSlug: knowledgeSlug,
      gamelanTypeSlug: gamelanSlug,
      knowledgeType: stringFrom(source, const [
            'knowledge_type_label',
          ]) ??
          (knowledgeSlug == null
              ? 'Unknown'
              : mapper.knowledgeLabelFromSlug(knowledgeSlug)),
      gamelanType: stringFrom(source, const ['gamelan_type_label']) ??
          (gamelanSlug == null
              ? 'Unknown'
              : mapper.gamelanLabelFromSlug(gamelanSlug)),
      sourceNote: stringFrom(source, const ['source_note']) ?? '',
      contributorNote: stringFrom(source, const ['contributor_note']) ?? '',
      culturalSensitivity: boolFrom(source, const ['cultural_sensitivity']),
      consentGiven: _consentFromApi(source),
      createdAt: createdAt,
      contributionIntent: stringFrom(source, const ['contribution_intent']),
      statusLabel: stringFrom(source, const ['status_label']),
      statusDescription: stringFrom(source, const ['status_description']),
      allowedActions: stringListFrom(source, const ['allowed_actions']),
      updatedAt: dateTimeFrom(source, const ['updated_at']),
      reviewNote: stringFrom(source, const ['review_note', 'latest_review_note']),
    );
  }

  static List<ContributionModel> listFromApi(
    Object? data, {
    TaxonomyMapper? taxonomy,
  }) {
    if (data is Iterable) {
      return data
          .map((entry) => fromApi(asObjectMap(entry), taxonomy: taxonomy))
          .whereType<ContributionModel>()
          .toList(growable: false);
    }

    final map = asObjectMap(data);
    final contributions = nestedObject(map, const ['contributions']);
    if (contributions != null) {
      return listFromApi(contributions, taxonomy: taxonomy);
    }

    final nestedList = map['data'];
    if (nestedList != null) {
      return listFromApi(nestedList, taxonomy: taxonomy);
    }

    final single = fromApi(map, taxonomy: taxonomy);
    if (single != null) {
      return [single];
    }
    return const [];
  }

  static bool _consentFromApi(Map<String, Object?> source) {
    final consentStatus = stringFrom(source, const ['consent_status']);
    if (consentStatus == null) {
      return boolFrom(source, const ['consent_given', 'consentGiven']);
    }
    return consentStatus == 'granted' || consentStatus == 'not_required';
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
    String? contributionIntent,
    String? statusLabel,
    String? statusDescription,
    List<String>? allowedActions,
    DateTime? updatedAt,
    String? reviewNote,
    String? knowledgeTypeSlug,
    String? gamelanTypeSlug,
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
      contributionIntent: contributionIntent ?? this.contributionIntent,
      statusLabel: statusLabel ?? this.statusLabel,
      statusDescription: statusDescription ?? this.statusDescription,
      allowedActions: allowedActions ?? this.allowedActions,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      knowledgeTypeSlug: knowledgeTypeSlug ?? this.knowledgeTypeSlug,
      gamelanTypeSlug: gamelanTypeSlug ?? this.gamelanTypeSlug,
    );
  }
}

extension ContributionStatusLabel on ContributionStatus {
  String get label => labelFor(
    ContributionModel(
      id: '',
      title: '',
      description: '',
      status: this,
      knowledgeType: '',
      gamelanType: '',
      sourceNote: '',
      contributorNote: '',
      culturalSensitivity: false,
      consentGiven: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );

  String labelFor(ContributionModel contribution) {
    final apiLabel = contribution.statusLabel?.trim();
    if (apiLabel != null && apiLabel.isNotEmpty) {
      return apiLabel;
    }

    return switch (this) {
      ContributionStatus.draft => 'Draft',
      ContributionStatus.submitted => 'Submitted',
      ContributionStatus.needsRevision => 'Needs revision',
      ContributionStatus.underReview => 'Under review',
      ContributionStatus.curatorApproved => 'Curator approved',
      ContributionStatus.expertRequired => 'Expert required',
      ContributionStatus.expertApproved => 'Expert approved',
      ContributionStatus.published => 'Published',
      ContributionStatus.rejected => 'Rejected',
      ContributionStatus.archived => 'Archived',
    };
  }
}

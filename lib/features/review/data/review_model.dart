enum ReviewDecision {
  pending,
  approved,
  rejected,
  needsChanges,
}

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.contributionId,
    required this.decision,
    this.notes,
  });

  final String id;
  final String contributionId;
  final ReviewDecision decision;
  final String? notes;
}

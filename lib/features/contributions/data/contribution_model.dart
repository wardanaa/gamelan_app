enum ContributionStatus { draft, submitted, underReview, approved, rejected }

class ContributionModel {
  const ContributionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final ContributionStatus status;
}

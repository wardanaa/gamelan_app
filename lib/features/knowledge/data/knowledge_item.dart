class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.knowledgeType,
    required this.gamelanType,
    required this.relations,
    required this.sourceSummary,
    required this.provenanceSummary,
    required this.isCommunityApproved,
  });

  final String id;
  final String title;
  final String description;
  final String knowledgeType;
  final String gamelanType;
  final List<String> relations;
  final String sourceSummary;
  final String provenanceSummary;
  final bool isCommunityApproved;
}

import '../../../core/api/api_parsers.dart';

class TriageSuggestion {
  const TriageSuggestion({
    required this.label,
    required this.provider,
    required this.status,
    required this.modelName,
    required this.processedAt,
    required this.confidenceScore,
    required this.suggestedEntityType,
    required this.suggestedRelations,
    required this.duplicateCandidates,
    required this.missingMetadata,
    required this.languageNormalization,
    required this.curatorSummary,
    required this.uncertaintyNotes,
  });

  final String label;
  final String provider;
  final String status;
  final String modelName;
  final DateTime? processedAt;
  final String? confidenceScore;
  final String? suggestedEntityType;
  final List<String> suggestedRelations;
  final List<String> duplicateCandidates;
  final List<String> missingMetadata;
  final Map<String, Object?> languageNormalization;
  final String? curatorSummary;
  final List<String> uncertaintyNotes;

  static TriageSuggestion? fromApi(Object? value) {
    final source = nestedObject(asObjectMap(value), const ['triage_suggestion']) ??
        asObjectMap(value);
    if (source.isEmpty) {
      return null;
    }

    final label = stringFrom(source, const ['label']);
    final provider = stringFrom(source, const ['provider']);
    final status = stringFrom(source, const ['status']);
    final modelName = stringFrom(source, const ['model_name']);
    if (label == null ||
        provider == null ||
        status == null ||
        modelName == null) {
      return null;
    }

    return TriageSuggestion(
      label: label,
      provider: provider,
      status: status,
      modelName: modelName,
      processedAt: dateTimeFrom(source, const ['processed_at']),
      confidenceScore: stringFrom(source, const ['confidence_score']),
      suggestedEntityType: stringFrom(source, const ['suggested_entity_type']),
      suggestedRelations: stringListFrom(source, const ['suggested_relations']),
      duplicateCandidates: stringListFrom(
        source,
        const ['duplicate_candidates'],
      ),
      missingMetadata: stringListFrom(source, const ['missing_metadata']),
      languageNormalization:
          asObjectMap(source['language_normalization']),
      curatorSummary: stringFrom(source, const ['curator_summary']),
      uncertaintyNotes: stringListFrom(source, const ['uncertainty_notes']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'label': label,
      'provider': provider,
      'status': status,
      'model_name': modelName,
      'processed_at': processedAt?.toIso8601String(),
      'confidence_score': confidenceScore,
      'suggested_entity_type': suggestedEntityType,
      'suggested_relations': suggestedRelations,
      'duplicate_candidates': duplicateCandidates,
      'missing_metadata': missingMetadata,
      'language_normalization': languageNormalization,
      'curator_summary': curatorSummary,
      'uncertainty_notes': uncertaintyNotes,
    };
  }
}

import '../../../core/api/api_parsers.dart';

class ProvenanceTimeline {
  const ProvenanceTimeline({required this.versions, required this.records});

  final List<ContributionVersionRecord> versions;
  final List<ProvenanceRecord> records;

  bool get isEmpty => versions.isEmpty && records.isEmpty;
}

class ContributionVersionRecord {
  const ContributionVersionRecord({
    required this.versionNumber,
    required this.status,
    required this.changeNote,
    required this.editedAt,
    required this.snapshot,
    this.editorName,
  });

  final int versionNumber;
  final String status;
  final String? changeNote;
  final String? editorName;
  final DateTime? editedAt;
  final Map<String, Object?> snapshot;

  static List<ContributionVersionRecord> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(ContributionVersionRecord.fromApi)
        .whereType<ContributionVersionRecord>()
        .toList(growable: false);
  }

  static ContributionVersionRecord? fromApi(Object? value) {
    final source = asObjectMap(value);
    final versionNumber = _intFrom(
      source['version_number'] ?? source['version'],
    );
    final status = stringFrom(source, const ['status']);
    if (versionNumber == null || status == null) {
      return null;
    }

    return ContributionVersionRecord(
      versionNumber: versionNumber,
      status: status,
      changeNote: stringFrom(source, const ['change_note']),
      editorName: stringFrom(
        nestedObject(source, const ['editor']) ?? source,
        const ['name'],
      ),
      editedAt: dateTimeFrom(source, const ['edited_at']),
      snapshot: asObjectMap(source['snapshot']),
    );
  }
}

class ProvenanceRecord {
  const ProvenanceRecord({
    required this.id,
    required this.eventType,
    required this.summary,
    required this.sourceType,
    required this.metadata,
    required this.occurredAt,
    this.actorName,
    this.contributionVersionNumber,
  });

  final String id;
  final String eventType;
  final String summary;
  final String? actorName;
  final String? sourceType;
  final int? contributionVersionNumber;
  final Map<String, Object?> metadata;
  final DateTime? occurredAt;

  static List<ProvenanceRecord> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(ProvenanceRecord.fromApi)
        .whereType<ProvenanceRecord>()
        .toList(growable: false);
  }

  static ProvenanceRecord? fromApi(Object? value) {
    final source = asObjectMap(value);
    final id = stringFrom(source, const ['id', 'uuid']);
    final eventType = stringFrom(source, const ['event_type']);
    final summary = stringFrom(source, const ['summary']);
    if (id == null || eventType == null || summary == null) {
      return null;
    }

    return ProvenanceRecord(
      id: id,
      eventType: eventType,
      summary: summary,
      actorName: stringFrom(
        nestedObject(source, const ['actor']) ?? source,
        const ['name'],
      ),
      sourceType: stringFrom(
        nestedObject(source, const ['source']) ?? source,
        const ['type'],
      ),
      contributionVersionNumber: _intFrom(
        source['contribution_version_number'],
      ),
      metadata: asObjectMap(source['metadata']),
      occurredAt: dateTimeFrom(source, const ['occurred_at']),
    );
  }
}

int? _intFrom(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

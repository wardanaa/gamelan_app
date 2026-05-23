import '../../../core/api/api_parsers.dart';

enum ProvenanceTimelineEntryKind { version, event }

class ProvenanceTimelineField {
  const ProvenanceTimelineField({required this.label, required this.value});

  final String label;
  final String value;
}

class ProvenanceTimelineEntry {
  const ProvenanceTimelineEntry({
    required this.id,
    required this.kind,
    required this.eventType,
    required this.title,
    required this.summary,
    required this.occurredAt,
    required this.actorLabel,
    required this.metadata,
  });

  final String id;
  final ProvenanceTimelineEntryKind kind;
  final String eventType;
  final String title;
  final String summary;
  final DateTime? occurredAt;
  final String? actorLabel;
  final List<ProvenanceTimelineField> metadata;

  String get safeActorLabel {
    final value = actorLabel?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'Actor withheld by backend policy';
  }

  String get kindLabel {
    return switch (kind) {
      ProvenanceTimelineEntryKind.version => 'Version',
      ProvenanceTimelineEntryKind.event => 'Provenance event',
    };
  }

  static List<ProvenanceTimelineEntry> listFromApi(
    Object? data, {
    required ProvenanceTimelineEntryKind kind,
  }) {
    if (data is Iterable) {
      return data
          .map((entry) => fromApi(asObjectMap(entry), kind: kind))
          .whereType<ProvenanceTimelineEntry>()
          .toList(growable: false);
    }

    final map = asObjectMap(data);
    final nestedData = map['data'];
    if (nestedData != null) {
      return listFromApi(nestedData, kind: kind);
    }

    final single = fromApi(map, kind: kind);
    if (single != null) {
      return [single];
    }
    return const [];
  }

  static ProvenanceTimelineEntry? fromApi(
    Map<String, Object?> source, {
    required ProvenanceTimelineEntryKind kind,
  }) {
    return switch (kind) {
      ProvenanceTimelineEntryKind.version => _fromVersionApi(source),
      ProvenanceTimelineEntryKind.event => _fromEventApi(source),
    };
  }

  static ProvenanceTimelineEntry? _fromVersionApi(Map<String, Object?> source) {
    final versionNumber = source['version_number'];
    final editor = nestedObject(source, const ['editor']) ?? const {};
    final snapshot = nestedObject(source, const ['snapshot']) ?? const {};
    final summary =
        stringFrom(source, const ['change_note']) ??
        'Version snapshot recorded.';
    final status = stringFrom(source, const ['status']);
    final editedAt = dateTimeFrom(source, const ['edited_at']);
    if (versionNumber == null || editedAt == null) {
      return null;
    }
    final title = 'Version $versionNumber';
    final actorLabel = stringFrom(editor, const ['name']);

    final metadata = <ProvenanceTimelineField>[
      ProvenanceTimelineField(
        label: 'Version',
        value: versionNumber.toString(),
      ),
      if (status != null && status.isNotEmpty)
        ProvenanceTimelineField(label: 'Status', value: status),
      if (stringFrom(snapshot, const ['title']) != null)
        ProvenanceTimelineField(
          label: 'Snapshot title',
          value: stringFrom(snapshot, const ['title'])!,
        ),
      if (stringFrom(snapshot, const ['status']) != null)
        ProvenanceTimelineField(
          label: 'Snapshot status',
          value: stringFrom(snapshot, const ['status'])!,
        ),
    ];

    return ProvenanceTimelineEntry(
      id: versionNumber.toString(),
      kind: ProvenanceTimelineEntryKind.version,
      eventType: 'version_snapshot',
      title: title,
      summary: summary,
      occurredAt: editedAt,
      actorLabel: actorLabel,
      metadata: metadata,
    );
  }

  static ProvenanceTimelineEntry? _fromEventApi(Map<String, Object?> source) {
    final eventType = stringFrom(source, const ['event_type']);
    final summary =
        stringFrom(source, const ['summary']) ??
        _humanize(eventType ?? 'provenance_event');
    final actor = nestedObject(source, const ['actor']) ?? const {};
    final sourceObject = nestedObject(source, const ['source']) ?? const {};
    final id = stringFrom(source, const ['id']);
    final occurredAt = dateTimeFrom(source, const ['occurred_at']);
    if (id == null || occurredAt == null) {
      return null;
    }
    final metadata = <ProvenanceTimelineField>[
      if (stringFrom(sourceObject, const ['type']) != null)
        ProvenanceTimelineField(
          label: 'Source',
          value: stringFrom(sourceObject, const ['type'])!,
        ),
      if (source['contribution_version_number'] != null)
        ProvenanceTimelineField(
          label: 'Contribution version',
          value: source['contribution_version_number'].toString(),
        ),
      ..._safeMetadataEntries(source['metadata']),
    ];

    return ProvenanceTimelineEntry(
      id: id,
      kind: ProvenanceTimelineEntryKind.event,
      eventType: eventType ?? 'provenance_event',
      title: _humanize(eventType ?? 'provenance_event'),
      summary: summary,
      occurredAt: occurredAt,
      actorLabel: stringFrom(actor, const ['name']),
      metadata: metadata,
    );
  }

  static List<ProvenanceTimelineField> _safeMetadataEntries(Object? value) {
    final map = asObjectMap(value);
    if (map.isEmpty) {
      return const [];
    }

    final fields = <ProvenanceTimelineField>[];
    for (final entry in map.entries) {
      final key = entry.key.trim();
      if (key.isEmpty || _isSensitiveKey(key)) {
        continue;
      }
      final label = _humanize(key);
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isNotEmpty) {
        fields.add(ProvenanceTimelineField(label: label, value: value.trim()));
        continue;
      }
      if (value is bool || value is num) {
        fields.add(ProvenanceTimelineField(label: label, value: '$value'));
        continue;
      }
      if (value is Iterable) {
        final items = value
            .map((item) => item?.toString().trim())
            .whereType<String>()
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        if (items.isNotEmpty) {
          fields.add(
            ProvenanceTimelineField(label: label, value: items.join(', ')),
          );
        }
        continue;
      }
      if (value is Map) {
        final nestedFields = _safeMetadataEntries(value);
        for (final nested in nestedFields) {
          fields.add(
            ProvenanceTimelineField(
              label: '$label / ${nested.label}',
              value: nested.value,
            ),
          );
        }
      }
    }
    return fields;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    const blockedFragments = [
      'private_note',
      'private notes',
      'reviewer',
      'expert_identity',
      'identity',
      'ip',
      'user_agent',
      'storage',
      'file_url',
      'url',
      'prompt',
      'response',
      'raw',
      'secret',
      'path',
    ];
    return blockedFragments.any(normalized.contains);
  }

  static String _humanize(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
          if (segment.length == 1) {
            return segment.toUpperCase();
          }
          return segment[0].toUpperCase() + segment.substring(1);
        })
        .join(' ');
  }
}

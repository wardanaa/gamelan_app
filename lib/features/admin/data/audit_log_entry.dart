import '../../../core/api/api_parsers.dart';

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.eventType,
    required this.summary,
    this.actorLabel,
    this.targetType,
    this.targetId,
    this.occurredAt,
  });

  final String id;
  final String eventType;
  final String summary;
  final String? actorLabel;
  final String? targetType;
  final String? targetId;
  final DateTime? occurredAt;

  String get safeActorLabel {
    final actor = actorLabel?.trim();
    if (actor == null || actor.isEmpty) {
      return 'Actor withheld by backend';
    }
    return actor;
  }

  String get targetLabel {
    final type = targetType?.trim();
    final idValue = targetId?.trim();
    if ((type == null || type.isEmpty) &&
        (idValue == null || idValue.isEmpty)) {
      return 'Target not returned';
    }
    if (type == null || type.isEmpty) {
      return idValue!;
    }
    if (idValue == null || idValue.isEmpty) {
      return type;
    }
    return '$type $idValue';
  }

  static AuditLogEntry? fromApi(Object? value) {
    final data = asObjectMap(value);
    if (data.isEmpty) {
      return null;
    }

    final id = _stringValue(data, const ['id', 'uuid', 'audit_log_id']);
    final eventType =
        stringFrom(data, const ['event_type', 'action', 'type']) ??
        'audit_event';
    final summary = stringFrom(data, const [
      'summary',
      'message',
      'description',
      'event',
    ]);
    if ((id == null || id.isEmpty) && (summary == null || summary.isEmpty)) {
      return null;
    }

    final actor = nestedObject(data, const ['actor', 'user']);
    final target = nestedObject(data, const ['target', 'subject']);

    return AuditLogEntry(
      id: id ?? summary!,
      eventType: eventType,
      summary: summary ?? eventType,
      actorLabel:
          _actorLabel(actor) ??
          stringFrom(data, const ['actor_name', 'user_name', 'causer_name']),
      targetType:
          stringFrom(target ?? const {}, const ['type', 'target_type']) ??
          stringFrom(data, const ['target_type', 'subject_type']),
      targetId:
          _stringValue(target ?? const {}, const ['id', 'uuid']) ??
          _stringValue(data, const ['target_id', 'subject_id']),
      occurredAt: dateTimeFrom(data, const [
        'occurred_at',
        'created_at',
        'logged_at',
      ]),
    );
  }

  static List<AuditLogEntry> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(AuditLogEntry.fromApi)
        .whereType<AuditLogEntry>()
        .toList(growable: false);
  }
}

String? _actorLabel(Map<String, Object?>? actor) {
  if (actor == null || actor.isEmpty) {
    return null;
  }
  return stringFrom(actor, const ['display_name', 'name', 'email']);
}

String? _stringValue(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

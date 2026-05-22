Map<String, Object?> asObjectMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry('$key', entry));
  }
  return const {};
}

List<Map<String, Object?>> asObjectMapList(Object? value) {
  if (value is! Iterable) {
    return const [];
  }

  return value
      .map(asObjectMap)
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

String? stringFrom(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool boolFrom(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is bool) {
      return value;
    }
  }
  return false;
}

DateTime? dateTimeFrom(Map<String, Object?> data, List<String> keys) {
  final value = stringFrom(data, keys);
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value);
}

List<String> stringListFrom(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    if (value is Iterable) {
      return value
          .map((entry) => entry?.toString().trim())
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
}

Map<String, Object?>? nestedObject(
  Map<String, Object?> data,
  List<String> keys,
) {
  for (final key in keys) {
    final value = data[key];
    if (value is Map<String, Object?> && value.isNotEmpty) {
      return value;
    }
    if (value is Map && value.isNotEmpty) {
      return asObjectMap(value);
    }
  }
  return null;
}

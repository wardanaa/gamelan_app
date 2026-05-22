class TaxonomyOption {
  const TaxonomyOption({required this.slug, required this.label});

  final String slug;
  final String label;
}

class TaxonomyMapper {
  TaxonomyMapper({
    List<TaxonomyOption>? knowledgeTypes,
    List<TaxonomyOption>? gamelanTypes,
  }) : knowledgeTypes = knowledgeTypes ?? defaultKnowledgeTypes,
       gamelanTypes = gamelanTypes ?? defaultGamelanTypes;

  static const defaultKnowledgeTypes = <TaxonomyOption>[
    TaxonomyOption(slug: 'instrument', label: 'Instrument'),
    TaxonomyOption(slug: 'ensemble', label: 'Ensemble'),
    TaxonomyOption(slug: 'composition', label: 'Composition'),
    TaxonomyOption(slug: 'technique', label: 'Technique'),
    TaxonomyOption(slug: 'person', label: 'Person'),
    TaxonomyOption(slug: 'group', label: 'Group'),
    TaxonomyOption(slug: 'place', label: 'Place'),
    TaxonomyOption(slug: 'term', label: 'Term'),
    TaxonomyOption(slug: 'media_asset', label: 'Media Asset'),
    TaxonomyOption(slug: 'source', label: 'Source'),
  ];

  static const defaultGamelanTypes = <TaxonomyOption>[
    TaxonomyOption(slug: 'gong_kebyar', label: 'Gong Kebyar'),
    TaxonomyOption(slug: 'gong_gede', label: 'Gong Gede'),
  ];

  static const contributionIntents = <TaxonomyOption>[
    TaxonomyOption(slug: 'new_entity', label: 'New entity'),
    TaxonomyOption(slug: 'correction', label: 'Correction'),
    TaxonomyOption(slug: 'add_relation', label: 'Add relation'),
    TaxonomyOption(slug: 'add_media', label: 'Add media'),
    TaxonomyOption(slug: 'add_source', label: 'Add source'),
  ];

  final List<TaxonomyOption> knowledgeTypes;
  final List<TaxonomyOption> gamelanTypes;

  List<String> get knowledgeTypeLabels =>
      knowledgeTypes.map((option) => option.label).toList(growable: false);

  List<String> get gamelanTypeLabels =>
      gamelanTypes.map((option) => option.label).toList(growable: false);

  String knowledgeSlugFromLabel(String label) {
    return _slugFromLabel(knowledgeTypes, label) ?? _normalizeSlug(label);
  }

  String gamelanSlugFromLabel(String label) {
    return _slugFromLabel(gamelanTypes, label) ?? _normalizeSlug(label);
  }

  String knowledgeLabelFromSlug(String slug) {
    return _labelFromSlug(knowledgeTypes, slug) ?? _titleCaseSlug(slug);
  }

  String gamelanLabelFromSlug(String slug) {
    return _labelFromSlug(gamelanTypes, slug) ?? _titleCaseSlug(slug);
  }

  static List<TaxonomyOption> optionsFromApiList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }

    final options = <TaxonomyOption>[];
    for (final entry in value) {
      if (entry is Map<String, Object?>) {
        final option = _optionFromMap(entry);
        if (option != null) {
          options.add(option);
        }
        continue;
      }
      if (entry is Map) {
        final option = _optionFromMap(
          entry.map((key, value) => MapEntry('$key', value)),
        );
        if (option != null) {
          options.add(option);
        }
        continue;
      }
      if (entry is String && entry.trim().isNotEmpty) {
        final slug = _normalizeSlug(entry);
        options.add(TaxonomyOption(slug: slug, label: _titleCaseSlug(slug)));
      }
    }
    return options;
  }

  static TaxonomyOption? _optionFromMap(Map<String, Object?> map) {
    final slug = _firstString(map, const ['slug', 'value', 'key', 'id']);
    final label = _firstString(map, const ['label', 'name', 'title']);
    if (slug == null) {
      return null;
    }
    return TaxonomyOption(
      slug: slug,
      label: label ?? _titleCaseSlug(slug),
    );
  }

  static String? _slugFromLabel(List<TaxonomyOption> options, String label) {
    final normalized = label.trim().toLowerCase();
    for (final option in options) {
      if (option.label.toLowerCase() == normalized ||
          option.slug == _normalizeSlug(label)) {
        return option.slug;
      }
    }
    return null;
  }

  static String? _labelFromSlug(List<TaxonomyOption> options, String slug) {
    final normalized = _normalizeSlug(slug);
    for (final option in options) {
      if (option.slug == normalized) {
        return option.label;
      }
    }
    return null;
  }

  static String? _firstString(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return _normalizeSlug(value);
      }
    }
    return null;
  }

  static String _normalizeSlug(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static String _titleCaseSlug(String slug) {
    return slug
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
        )
        .join(' ');
  }
}

import 'dart:typed_data';

import '../../../core/api/api_parsers.dart';

enum MediaType {
  image,
  audio,
  video,
  document;

  String get apiValue => name;

  String get label => switch (this) {
    MediaType.image => 'Image',
    MediaType.audio => 'Audio',
    MediaType.video => 'Video',
    MediaType.document => 'Document',
  };

  static MediaType fromApiValue(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'audio' => MediaType.audio,
      'video' => MediaType.video,
      'document' => MediaType.document,
      _ => MediaType.image,
    };
  }
}

enum MediaConsentStatus {
  unknown,
  granted,
  restricted,
  revoked,
  notRequired;

  String get apiValue => switch (this) {
    MediaConsentStatus.notRequired => 'not_required',
    _ => name,
  };

  String get label => switch (this) {
    MediaConsentStatus.unknown => 'Unknown',
    MediaConsentStatus.granted => 'Granted',
    MediaConsentStatus.restricted => 'Restricted',
    MediaConsentStatus.revoked => 'Revoked',
    MediaConsentStatus.notRequired => 'Not required',
  };

  bool get permitsPublic =>
      this == MediaConsentStatus.granted ||
      this == MediaConsentStatus.notRequired;

  static MediaConsentStatus fromApiValue(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'granted' => MediaConsentStatus.granted,
      'restricted' => MediaConsentStatus.restricted,
      'revoked' => MediaConsentStatus.revoked,
      'not_required' => MediaConsentStatus.notRequired,
      _ => MediaConsentStatus.unknown,
    };
  }
}

enum MediaVisibility {
  private,
  restricted,
  curatorOnly,
  expertOnly,
  public;

  String get apiValue => switch (this) {
    MediaVisibility.curatorOnly => 'curator_only',
    MediaVisibility.expertOnly => 'expert_only',
    _ => name,
  };

  String get label => switch (this) {
    MediaVisibility.private => 'Private',
    MediaVisibility.restricted => 'Restricted',
    MediaVisibility.curatorOnly => 'Curator only',
    MediaVisibility.expertOnly => 'Expert only',
    MediaVisibility.public => 'Public',
  };

  static MediaVisibility fromApiValue(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'public' => MediaVisibility.public,
      'restricted' => MediaVisibility.restricted,
      'curator_only' => MediaVisibility.curatorOnly,
      'expert_only' => MediaVisibility.expertOnly,
      _ => MediaVisibility.private,
    };
  }
}

class MediaAssetModel {
  const MediaAssetModel({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.consentStatus,
    required this.visibility,
    required this.culturalSensitivity,
    this.description,
    this.mimeType,
    this.fileSize,
    this.creator,
    this.credit,
    this.license,
    this.recordingDate,
    this.recordingPlace,
    this.relatedEntityLabel,
    this.altText,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final MediaType mediaType;
  final String? mimeType;
  final int? fileSize;
  final String? creator;
  final String? credit;
  final String? license;
  final MediaConsentStatus consentStatus;
  final MediaVisibility visibility;
  final bool culturalSensitivity;
  final String? recordingDate;
  final String? recordingPlace;
  final String? relatedEntityLabel;
  final String? altText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static MediaAssetModel? fromApi(Object? value) {
    final source =
        nestedObject(asObjectMap(value), const ['media_asset']) ??
        asObjectMap(value);
    final id = stringFrom(source, const ['id', 'uuid']);
    final title = stringFrom(source, const ['title']);
    final mediaType = stringFrom(source, const ['media_type']);
    if (id == null || title == null || mediaType == null) {
      return null;
    }

    final consentStatus = stringFrom(source, const ['consent_status']);
    final visibility = stringFrom(source, const ['visibility']);
    return MediaAssetModel(
      id: id,
      title: title,
      description: stringFrom(source, const ['description']),
      mediaType: MediaType.fromApiValue(mediaType),
      mimeType: stringFrom(source, const ['mime_type']),
      fileSize: _intFrom(source['file_size']),
      creator: stringFrom(source, const ['creator']),
      credit: stringFrom(source, const ['credit']),
      license: stringFrom(source, const ['license']),
      consentStatus: consentStatus == null
          ? MediaConsentStatus.unknown
          : MediaConsentStatus.fromApiValue(consentStatus),
      visibility: visibility == null
          ? MediaVisibility.private
          : MediaVisibility.fromApiValue(visibility),
      culturalSensitivity: boolFrom(source, const ['cultural_sensitivity']),
      recordingDate: stringFrom(source, const ['recording_date']),
      recordingPlace: stringFrom(source, const ['recording_place']),
      relatedEntityLabel: stringFrom(source, const ['related_entity_label']),
      altText: stringFrom(source, const ['alt_text']),
      createdAt: dateTimeFrom(source, const ['created_at']),
      updatedAt: dateTimeFrom(source, const ['updated_at']),
    );
  }

  static List<MediaAssetModel> listFromApi(Object? value) {
    if (value is Iterable) {
      return value
          .map(MediaAssetModel.fromApi)
          .whereType<MediaAssetModel>()
          .toList(growable: false);
    }

    final map = asObjectMap(value);
    final nested = map['media_assets'];
    if (nested != null) {
      return listFromApi(nested);
    }

    final single = fromApi(map);
    return single == null ? const [] : [single];
  }

  static int? _intFrom(Object? value) {
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
}

class MediaUploadInput {
  const MediaUploadInput({
    required this.title,
    required this.mediaType,
    required this.consentStatus,
    required this.visibility,
    required this.culturalSensitivity,
    required this.filename,
    this.filePath,
    this.bytes,
    this.description,
    this.creator,
    this.credit,
    this.license,
    this.recordingDate,
    this.recordingPlace,
    this.relatedEntityLabel,
    this.altText,
  });

  final String title;
  final MediaType mediaType;
  final MediaConsentStatus consentStatus;
  final MediaVisibility visibility;
  final bool culturalSensitivity;
  final String filename;
  final String? filePath;
  final Uint8List? bytes;
  final String? description;
  final String? creator;
  final String? credit;
  final String? license;
  final String? recordingDate;
  final String? recordingPlace;
  final String? relatedEntityLabel;
  final String? altText;

  Map<String, String> toMultipartFields() {
    final fields = <String, String>{
      'title': title.trim(),
      'media_type': mediaType.apiValue,
      'consent_status': consentStatus.apiValue,
      'visibility': visibility.apiValue,
      'cultural_sensitivity': culturalSensitivity ? '1' : '0',
    };
    _addIfPresent(fields, 'description', description);
    _addIfPresent(fields, 'creator', creator);
    _addIfPresent(fields, 'credit', credit);
    _addIfPresent(fields, 'license', license);
    _addIfPresent(fields, 'recording_date', recordingDate);
    _addIfPresent(fields, 'recording_place', recordingPlace);
    _addIfPresent(fields, 'related_entity_label', relatedEntityLabel);
    _addIfPresent(fields, 'alt_text', altText);
    return fields;
  }

  static void _addIfPresent(
    Map<String, String> fields,
    String key,
    String? value,
  ) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      fields[key] = trimmed;
    }
  }
}

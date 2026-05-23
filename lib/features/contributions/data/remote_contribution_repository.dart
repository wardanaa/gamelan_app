import '../../../core/api/api_client.dart';
import '../../../core/api/repository_errors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/utils/result.dart';
import '../../provenance/data/provenance_timeline_entry.dart';
import 'contribution_model.dart';
import 'contribution_repository.dart';
import 'media_asset_model.dart';

typedef TokenResolver = Future<String?> Function();

class RemoteContributionRepository implements ContributionRepository {
  RemoteContributionRepository({
    required ApiClient apiClient,
    required TokenResolver tokenResolver,
    TaxonomyMapper? taxonomyMapper,
  }) : _apiClient = apiClient,
       _tokenResolver = tokenResolver,
       _taxonomyMapper = taxonomyMapper ?? TaxonomyMapper();

  final ApiClient _apiClient;
  final TokenResolver _tokenResolver;
  final TaxonomyMapper _taxonomyMapper;

  @override
  Future<void> loadPersistedDrafts() async {}

  @override
  Future<Result<List<ContributionModel>>> fetchContributions() async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.contributions,
        token: token,
      );
      final contributions = ContributionModel.listFromApi(
        response.data,
        taxonomy: _taxonomyMapper,
      );
      return Success(contributions);
    });
  }

  @override
  Future<Result<ContributionModel?>> findContribution(String id) async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.contribution(id),
        token: token,
      );
      final contribution = ContributionModel.fromApi(
        response.dataMap,
        taxonomy: _taxonomyMapper,
      );
      return Success(contribution);
    });
  }

  @override
  Future<Result<Map<ContributionStatus, int>>> fetchStatusCounts() async {
    final contributionsResult = await fetchContributions();
    return switch (contributionsResult) {
      Success<List<ContributionModel>>(:final value) => Success({
        for (final status in ContributionStatus.values)
          status: value.where((item) => item.status == status).length,
      }),
      Failure<List<ContributionModel>>(:final message, :final exception) =>
        Failure(message, exception: exception),
    };
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionVersions(
    String contributionId,
  ) async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.contributionVersions(contributionId),
        token: token,
      );
      final versions = ProvenanceTimelineEntry.listFromApi(
        response.data,
        kind: ProvenanceTimelineEntryKind.version,
      );
      return Success(versions);
    });
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionProvenance(
    String contributionId,
  ) async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.contributionProvenance(contributionId),
        token: token,
      );
      final provenance = ProvenanceTimelineEntry.listFromApi(
        response.data,
        kind: ProvenanceTimelineEntryKind.event,
      );
      return Success(provenance);
    });
  }

  @override
  Future<Result<ContributionModel>> createContribution(
    ContributionInput input,
  ) async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.postJson(
        ApiEndpoints.contributions,
        token: token,
        body: _payloadFromInput(
          input,
          includeOptionalFields: !input.submitForReview,
        ),
      );
      final contribution = ContributionModel.fromApi(
        response.dataMap,
        taxonomy: _taxonomyMapper,
      );
      if (contribution == null) {
        return const Failure('The server returned an invalid contribution.');
      }

      if (input.submitForReview) {
        return submitContribution(contribution.id);
      }
      return Success(contribution);
    });
  }

  @override
  Future<Result<ContributionModel>> updateContribution(
    String id,
    ContributionInput input, {
    DateTime? lastKnownUpdatedAt,
  }) async {
    return _runAuthenticated((token) async {
      final body = _payloadFromInput(
        input,
        includeOptionalFields: true,
        lastKnownUpdatedAt: lastKnownUpdatedAt,
      );
      final response = await _apiClient.putJson(
        ApiEndpoints.contribution(id),
        token: token,
        body: body,
      );
      final contribution = ContributionModel.fromApi(
        response.dataMap,
        taxonomy: _taxonomyMapper,
      );
      if (contribution == null) {
        return const Failure('The server returned an invalid contribution.');
      }
      return Success(contribution);
    });
  }

  @override
  Future<Result<ContributionModel>> submitContribution(String id) async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.postJson(
        ApiEndpoints.contributionSubmit(id),
        token: token,
      );
      final contribution = ContributionModel.fromApi(
        response.dataMap,
        taxonomy: _taxonomyMapper,
      );
      if (contribution == null) {
        return const Failure('The server returned an invalid contribution.');
      }
      return Success(contribution);
    });
  }

  @override
  Future<Result<void>> archiveContribution(String id) async {
    return _runAuthenticated((token) async {
      await _apiClient.deleteJson(ApiEndpoints.contribution(id), token: token);
      return const Success(null);
    });
  }

  @override
  Future<Result<MediaAssetModel>> uploadMedia(
    String contributionId,
    MediaUploadInput input,
  ) async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.postMultipart(
        ApiEndpoints.contributionMedia(contributionId),
        token: token,
        idempotencyKey: _idempotencyKey('media-upload'),
        fields: input.toMultipartFields(),
        fileField: 'file',
        filePath: input.filePath,
        bytes: input.bytes,
        filename: input.filename,
      );
      final mediaAsset = MediaAssetModel.fromApi(response.dataMap);
      if (mediaAsset == null) {
        return const Failure('The server returned an invalid media asset.');
      }
      return Success(mediaAsset);
    });
  }

  @override
  Future<Result<void>> removeMedia(
    String contributionId,
    String mediaAssetId,
  ) async {
    return _runAuthenticated((token) async {
      await _apiClient.deleteJson(
        ApiEndpoints.contributionMediaItem(contributionId, mediaAssetId),
        token: token,
        idempotencyKey: _idempotencyKey('media-remove'),
      );
      return const Success(null);
    });
  }

  Map<String, Object?> _payloadFromInput(
    ContributionInput input, {
    required bool includeOptionalFields,
    DateTime? lastKnownUpdatedAt,
  }) {
    final knowledgeSlug =
        input.knowledgeTypeSlug ??
        _taxonomyMapper.knowledgeSlugFromLabel(input.knowledgeType);
    final gamelanSlug =
        input.gamelanTypeSlug ??
        _taxonomyMapper.gamelanSlugFromLabel(input.gamelanType);

    final payload = <String, Object?>{
      'title': input.title.trim(),
      'knowledge_type': knowledgeSlug,
      'gamelan_type': gamelanSlug,
      'cultural_sensitivity': input.culturalSensitivity,
      'consent_status': input.consentGiven ? 'granted' : 'pending',
    };

    if (includeOptionalFields || input.description.trim().isNotEmpty) {
      payload['description'] = input.description.trim();
    }
    if (includeOptionalFields || input.sourceNote.trim().isNotEmpty) {
      payload['source_note'] = input.sourceNote.trim();
    }
    if (input.contributorNote.trim().isNotEmpty) {
      payload['contributor_note'] = input.contributorNote.trim();
    }
    if (input.contributionIntent != null &&
        input.contributionIntent!.trim().isNotEmpty) {
      payload['contribution_intent'] = input.contributionIntent!.trim();
    }
    if (lastKnownUpdatedAt != null) {
      payload['last_known_updated_at'] = lastKnownUpdatedAt
          .toUtc()
          .toIso8601String();
    }

    return payload;
  }

  Future<Result<T>> _runAuthenticated<T>(
    Future<Result<T>> Function(String token) action,
  ) async {
    final token = await _tokenResolver();
    if (token == null || token.isEmpty) {
      return const Failure('Please sign in to continue.');
    }

    try {
      return await action(token);
    } on ApiException catch (exception) {
      final validation = validationExceptionFrom(exception);
      if (validation != null) {
        return Failure(validation.message, exception: validation);
      }
      final conflict = conflictExceptionFrom(exception);
      if (conflict != null) {
        return Failure(conflict.message, exception: conflict);
      }
      return Failure(messageFromApiException(exception), exception: exception);
    } on FormatException catch (exception) {
      return Failure(
        'The server returned an invalid response.',
        exception: exception,
      );
    } on Object catch (exception) {
      return Failure('Unable to reach the server.', exception: exception);
    }
  }

  String _idempotencyKey(String purpose) {
    return '$purpose-${DateTime.now().microsecondsSinceEpoch}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/state/gamelan_mvp_store.dart';
import 'package:gamelan_app/core/state/gamelan_scope.dart';
import 'package:gamelan_app/core/mapping/taxonomy_mapper.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/contributions/data/media_asset_model.dart';
import 'package:gamelan_app/features/contributions/data/rdf_publication_model.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_item.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_repository.dart';
import 'package:gamelan_app/features/ontology/data/ontology_mapping.dart';
import 'package:gamelan_app/features/provenance/data/provenance_timeline_entry.dart';
import 'package:gamelan_app/features/provenance/screens/provenance_timeline_screen.dart';
import 'package:gamelan_app/features/review/data/review_repository.dart';

void main() {
  testWidgets('provenance timeline renders safe trace fields', (
    WidgetTester tester,
  ) async {
    final store = _TraceStore(
      contributionVersions: const Success([
        ProvenanceTimelineEntry(
          id: '2',
          kind: ProvenanceTimelineEntryKind.version,
          eventType: 'version_snapshot',
          title: 'Version 2',
          summary: 'Submitted for review.',
          occurredAt: null,
          actorLabel: 'Made Contributor',
          metadata: [
            ProvenanceTimelineField(label: 'Version', value: '2'),
            ProvenanceTimelineField(label: 'Status', value: 'submitted'),
          ],
        ),
      ]),
      contributionProvenance: const Success([
        ProvenanceTimelineEntry(
          id: 'provenance-1',
          kind: ProvenanceTimelineEntryKind.event,
          eventType: 'contribution_submitted',
          title: 'Contribution submitted',
          summary: 'Contribution submitted for review.',
          occurredAt: null,
          actorLabel: null,
          metadata: [
            ProvenanceTimelineField(label: 'Source', value: 'Contribution'),
            ProvenanceTimelineField(label: 'Contribution version', value: '2'),
          ],
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GamelanScope(
          store: store,
          child: const ProvenanceTimelineScreen.contribution(
            contributionId: 'contribution-uuid',
            subjectTitle: 'Gangsa note',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gangsa note'), findsOneWidget);
    expect(find.text('Version 2'), findsOneWidget);
    expect(find.text('Contribution submitted'), findsOneWidget);
    expect(find.text('Actor withheld by backend policy'), findsOneWidget);
    expect(find.text('Status: submitted'), findsOneWidget);
    expect(find.text('Private note'), findsNothing);
    expect(find.textContaining('http://'), findsNothing);
    expect(find.textContaining('https://'), findsNothing);
  });

  testWidgets('provenance timeline shows a safe error for forbidden traces', (
    WidgetTester tester,
  ) async {
    final store = _TraceStore(
      contributionVersions: const Failure(
        'You do not have permission to perform this action.',
      ),
      contributionProvenance: const Failure(
        'You do not have permission to perform this action.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GamelanScope(
          store: store,
          child: const ProvenanceTimelineScreen.contribution(
            contributionId: 'contribution-uuid',
            subjectTitle: 'Gangsa note',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trace data is unavailable right now.'), findsOneWidget);
  });
}

class _TraceStore extends GamelanMvpStore {
  _TraceStore({
    required Result<List<ProvenanceTimelineEntry>> contributionVersions,
    required Result<List<ProvenanceTimelineEntry>> contributionProvenance,
    Result<List<ProvenanceTimelineEntry>> reviewProvenance = const Success(
      <ProvenanceTimelineEntry>[],
    ),
  }) : _contributionVersions = contributionVersions,
       _contributionProvenance = contributionProvenance,
       _reviewProvenance = reviewProvenance,
       super(
         contributionRepository: _NoopContributionRepository(),
         reviewRepository: _NoopReviewRepository(),
         knowledgeRepository: _NoopKnowledgeRepository(),
       );

  final Result<List<ProvenanceTimelineEntry>> _contributionVersions;
  final Result<List<ProvenanceTimelineEntry>> _contributionProvenance;
  final Result<List<ProvenanceTimelineEntry>> _reviewProvenance;

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionVersions(
    String contributionId,
  ) async {
    return _contributionVersions;
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionProvenance(
    String contributionId,
  ) async {
    return _contributionProvenance;
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchReviewProvenance(
    String contributionId,
  ) async {
    return _reviewProvenance;
  }
}

class _NoopContributionRepository implements ContributionRepository {
  @override
  Future<void> loadPersistedDrafts() async {}

  @override
  Future<Result<List<ContributionModel>>> fetchContributions() async {
    return const Success(<ContributionModel>[]);
  }

  @override
  Future<Result<ContributionModel?>> findContribution(String id) async {
    return const Success(null);
  }

  @override
  Future<Result<RdfPublicationModel>> queueRdfPublication(
    String uuid,
    OntologyMapping mapping,
  ) async {
    return const Failure('Not implemented.');
  }

  @override
  Future<Result<RdfPublicationModel?>> getRdfPublication(String uuid) async {
    return const Success(null);
  }

  @override
  Future<Result<Map<ContributionStatus, int>>> fetchStatusCounts() async {
    return Success({for (final status in ContributionStatus.values) status: 0});
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionVersions(
    String contributionId,
  ) async {
    return const Success(<ProvenanceTimelineEntry>[]);
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionProvenance(
    String contributionId,
  ) async {
    return const Success(<ProvenanceTimelineEntry>[]);
  }

  @override
  Future<Result<ContributionModel>> createContribution(
    ContributionInput input,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<ContributionModel>> updateContribution(
    String id,
    ContributionInput input, {
    DateTime? lastKnownUpdatedAt,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<ContributionModel>> submitContribution(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> archiveContribution(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<MediaAssetModel>> uploadMedia(
    String contributionId,
    MediaUploadInput input,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> removeMedia(
    String contributionId,
    String mediaAssetId,
  ) async {
    throw UnimplementedError();
  }
}

class _NoopReviewRepository implements ReviewRepository {
  @override
  Future<Result<List<ContributionModel>>> fetchReviewQueue() async {
    return const Success(<ContributionModel>[]);
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchReviewProvenance(
    String contributionId,
  ) async {
    return const Success(<ProvenanceTimelineEntry>[]);
  }

  @override
  Future<Result<void>> approveContribution(
    String contributionId,
    String note,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> rejectContribution(
    String contributionId,
    String note,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> requestChanges(
    String contributionId,
    String note,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> markExpertRequired(
    String contributionId,
    String note,
    List<String> reasons,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> expertValidate(
    String contributionId,
    String decision,
    String note,
    String privateNote,
  ) async {
    throw UnimplementedError();
  }
}

class _NoopKnowledgeRepository implements KnowledgeRepository {
  @override
  Future<Result<List<KnowledgeItem>>> fetchKnowledgeItems() async {
    return const Success(<KnowledgeItem>[]);
  }

  @override
  Future<Result<KnowledgeItem?>> findKnowledgeItem(String id) async {
    return const Success(null);
  }

  @override
  Future<Result<KnowledgeSearchResult>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
    String? gamelanTypeSlug,
    String? knowledgeTypeSlug,
  }) async {
    return Success(KnowledgeSearchResult.keyword(const <KnowledgeItem>[]));
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchKnowledgeTypes() async {
    return const Success(<TaxonomyOption>[]);
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchGamelanTypes() async {
    return const Success(<TaxonomyOption>[]);
  }
}

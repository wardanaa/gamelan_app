import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/contributions/data/media_asset_model.dart';
import 'package:gamelan_app/features/contributions/data/rdf_publication_model.dart';
import 'package:gamelan_app/features/knowledge/data/local_knowledge_repository.dart';
import 'package:gamelan_app/features/ontology/data/ontology_mapping.dart';
import 'package:gamelan_app/features/review/data/review_repository.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'contribution status values and labels include expert workflow states',
    () {
      expect(ContributionStatus.expertRequired.apiValue, 'expert_required');
      expect(ContributionStatus.expertApproved.apiValue, 'expert_approved');
      expect(ContributionStatus.published.apiValue, 'published');
      expect(ContributionStatus.archived.apiValue, 'archived');

      expect(ContributionStatus.expertRequired.label, 'Expert required');
      expect(ContributionStatus.expertApproved.label, 'Expert approved');
      expect(ContributionStatus.published.label, 'Published');
      expect(ContributionStatus.archived.label, 'Archived');

      expect(
        ContributionStatus.fromApiValue('expert_required'),
        ContributionStatus.expertRequired,
      );
      expect(
        ContributionStatus.fromApiValue('expert_approved'),
        ContributionStatus.expertApproved,
      );
      expect(
        ContributionStatus.fromApiValue('published'),
        ContributionStatus.published,
      );
      expect(
        ContributionStatus.fromApiValue('archived'),
        ContributionStatus.archived,
      );
    },
  );

  test('local contribution repository includes initial demo seed', () async {
    final repository = LocalContributionRepository();

    final contributionsResult = await repository.fetchContributions();
    final contributions = switch (contributionsResult) {
      Success<List<ContributionModel>>(:final value) => value,
      Failure<List<ContributionModel>>() => fail('Expected success'),
    };

    expect(contributions, hasLength(1));
    expect(contributions.single.id, 'demo-sensitive-source');
    expect(contributions.single.status, ContributionStatus.submitted);
    expect(contributions.single.culturalSensitivity, isTrue);
  });

  test('local contribution repository persists non-sensitive drafts', () async {
    final firstRepository = LocalContributionRepository();
    await firstRepository.createContribution(
      contributionInput(
        title: 'Persistent gangsa draft',
        submitForReview: false,
      ),
    );

    final secondRepository = LocalContributionRepository();
    await secondRepository.loadPersistedDrafts();
    final contributionsResult = await secondRepository.fetchContributions();
    final contributions = switch (contributionsResult) {
      Success<List<ContributionModel>>(:final value) => value,
      Failure<List<ContributionModel>>() => fail('Expected success'),
    };

    expect(
      contributions.map((contribution) => contribution.title),
      contains('Persistent gangsa draft'),
    );
    expect(
      contributions
          .singleWhere(
            (contribution) => contribution.title == 'Persistent gangsa draft',
          )
          .status,
      ContributionStatus.draft,
    );
  });

  test(
    'local contribution repository does not persist sensitive drafts',
    () async {
      final firstRepository = LocalContributionRepository();
      await firstRepository.createContribution(
        contributionInput(
          title: 'Sensitive ceremony draft',
          culturalSensitivity: true,
          submitForReview: false,
        ),
      );

      final secondRepository = LocalContributionRepository();
      await secondRepository.loadPersistedDrafts();
      final contributionsResult = await secondRepository.fetchContributions();
      final contributions = switch (contributionsResult) {
        Success<List<ContributionModel>>(:final value) => value,
        Failure<List<ContributionModel>>() => fail('Expected success'),
      };

      expect(
        contributions.map((contribution) => contribution.title),
        isNot(contains('Sensitive ceremony draft')),
      );
    },
  );

  test(
    'local contribution repository does not persist submitted items',
    () async {
      final firstRepository = LocalContributionRepository();
      await firstRepository.createContribution(
        contributionInput(title: 'Submitted reyong note'),
      );

      final secondRepository = LocalContributionRepository();
      await secondRepository.loadPersistedDrafts();
      final contributionsResult = await secondRepository.fetchContributions();
      final contributions = switch (contributionsResult) {
        Success<List<ContributionModel>>(:final value) => value,
        Failure<List<ContributionModel>>() => fail('Expected success'),
      };

      expect(
        contributions.map((contribution) => contribution.title),
        isNot(contains('Submitted reyong note')),
      );
    },
  );

  test(
    'local contribution repository keeps media attachments in memory only',
    () async {
      final firstRepository = LocalContributionRepository();
      final draftResult = await firstRepository.createContribution(
        contributionInput(title: 'Draft with media', submitForReview: false),
      );
      final draft = switch (draftResult) {
        Success<ContributionModel>(:final value) => value,
        Failure<ContributionModel>() => fail('Expected success'),
      };

      final uploadResult = await firstRepository.uploadMedia(
        draft.id,
        const MediaUploadInput(
          title: 'Gangsa photo',
          mediaType: MediaType.image,
          consentStatus: MediaConsentStatus.granted,
          visibility: MediaVisibility.private,
          culturalSensitivity: false,
          filename: 'gangsa.jpg',
        ),
      );
      final asset = switch (uploadResult) {
        Success<MediaAssetModel>(:final value) => value,
        Failure<MediaAssetModel>() => fail('Expected success'),
      };

      final loadedResult = await firstRepository.findContribution(draft.id);
      final loaded = switch (loadedResult) {
        Success<ContributionModel?>(:final value) => value,
        Failure<ContributionModel?>() => fail('Expected success'),
      };
      expect(loaded?.mediaAssets.single.title, 'Gangsa photo');

      final removeResult = await firstRepository.removeMedia(
        draft.id,
        asset.id,
      );
      expect(removeResult, isA<Success<void>>());
      final removedResult = await firstRepository.findContribution(draft.id);
      final removed = switch (removedResult) {
        Success<ContributionModel?>(:final value) => value,
        Failure<ContributionModel?>() => fail('Expected success'),
      };
      expect(removed?.mediaAssets, isEmpty);

      await firstRepository.uploadMedia(
        draft.id,
        const MediaUploadInput(
          title: 'Non-persisted photo',
          mediaType: MediaType.image,
          consentStatus: MediaConsentStatus.granted,
          visibility: MediaVisibility.private,
          culturalSensitivity: false,
          filename: 'gangsa.jpg',
        ),
      );
      final secondRepository = LocalContributionRepository();
      await secondRepository.loadPersistedDrafts();
      final persistedResult = await secondRepository.findContribution(draft.id);
      final persisted = switch (persistedResult) {
        Success<ContributionModel?>(:final value) => value,
        Failure<ContributionModel?>() => fail('Expected success'),
      };
      expect(persisted?.mediaAssets, isEmpty);
    },
  );

  test(
    'local contribution repository keeps rdf publication state in memory only',
    () async {
      final repository = LocalContributionRepository();
      final contributionResult = await repository.createContribution(
        contributionInput(
          title: 'Publishable local note',
          submitForReview: false,
        ),
      );
      final contribution = switch (contributionResult) {
        Success<ContributionModel>(:final value) => value,
        Failure<ContributionModel>() => fail('Expected success'),
      };

      await repository.updateContributionStatus(
        contribution.id,
        ContributionStatus.curatorApproved,
      );

      final mapping = OntologyMapping(
        id: 'mapping-uuid',
        contributionId: contribution.id,
        knowledgeItemId: null,
        ontologyClass: 'Instrument',
        subjectSlug: 'publishable-local-note',
        preferredLabel: 'Publishable local note',
        language: 'id',
        relations: const [],
        status: 'pending',
        createdAt: DateTime(2026, 5, 22, 10),
      );

      final queueResult = await repository.queueRdfPublication(
        contribution.id,
        mapping,
      );
      final publication = switch (queueResult) {
        Success<RdfPublicationModel>(:final value) => value,
        Failure<RdfPublicationModel>(:final message) => fail(message),
      };

      final loadedResult = await repository.findContribution(contribution.id);
      final loaded = switch (loadedResult) {
        Success<ContributionModel?>(:final value) => value,
        Failure<ContributionModel?>() => fail('Expected success'),
      };
      expect(loaded?.rdfPublication?.id, publication.id);

      final publicationResult = await repository.getRdfPublication(
        contribution.id,
      );
      final loadedPublication = switch (publicationResult) {
        Success<RdfPublicationModel?>(:final value) => value,
        Failure<RdfPublicationModel?>() => fail('Expected success'),
      };
      expect(loadedPublication?.status, RdfPublicationStatus.pending);
      expect(loadedPublication?.ontologyMappingId, 'mapping-uuid');
    },
  );

  test(
    'local review repository filters submitted and under-review items',
    () async {
      final contributions = LocalContributionRepository();
      final reviewRepository = LocalReviewRepository(
        contributions: contributions,
      );
      await contributions.createContribution(
        contributionInput(title: 'Local draft', submitForReview: false),
      );
      await contributions.createContribution(
        contributionInput(title: 'Submitted note'),
      );
      final approvedResult = await contributions.createContribution(
        contributionInput(title: 'Approved note'),
      );
      final approved = switch (approvedResult) {
        Success<ContributionModel>(:final value) => value,
        Failure<ContributionModel>() => fail('Expected success'),
      };
      await reviewRepository.approveContribution(approved.id, 'Approved.');
      final underReviewResult = await contributions.createContribution(
        contributionInput(title: 'Under-review note'),
      );
      final underReview = switch (underReviewResult) {
        Success<ContributionModel>(:final value) => value,
        Failure<ContributionModel>() => fail('Expected success'),
      };
      await contributions.updateContributionStatus(
        underReview.id,
        ContributionStatus.underReview,
      );

      final queueResult = await reviewRepository.fetchReviewQueue();
      final queue = switch (queueResult) {
        Success<List<ContributionModel>>(:final value) => value,
        Failure<List<ContributionModel>>() => fail('Expected success'),
      };
      final titles = queue.map((contribution) => contribution.title);

      expect(titles, contains('Ceremonial Gong Gede source note'));
      expect(titles, contains('Submitted note'));
      expect(titles, contains('Under-review note'));
      expect(titles, isNot(contains('Local draft')));
      expect(titles, isNot(contains('Approved note')));
    },
  );

  test('local review repository updates decision statuses and notes', () async {
    final contributions = LocalContributionRepository();
    final reviewRepository = LocalReviewRepository(
      contributions: contributions,
    );
    final underReviewResult = await contributions.createContribution(
      contributionInput(title: 'Under review item'),
    );
    final approvedResult = await contributions.createContribution(
      contributionInput(title: 'Approved item'),
    );
    final rejectedResult = await contributions.createContribution(
      contributionInput(title: 'Rejected item'),
    );
    final changesResult = await contributions.createContribution(
      contributionInput(title: 'Changes item'),
    );

    final underReview = switch (underReviewResult) {
      Success<ContributionModel>(:final value) => value,
      Failure<ContributionModel>() => fail('Expected success'),
    };
    final approved = switch (approvedResult) {
      Success<ContributionModel>(:final value) => value,
      Failure<ContributionModel>() => fail('Expected success'),
    };
    final rejected = switch (rejectedResult) {
      Success<ContributionModel>(:final value) => value,
      Failure<ContributionModel>() => fail('Expected success'),
    };
    final changes = switch (changesResult) {
      Success<ContributionModel>(:final value) => value,
      Failure<ContributionModel>() => fail('Expected success'),
    };

    await contributions.updateContributionStatus(
      underReview.id,
      ContributionStatus.underReview,
    );
    await reviewRepository.approveContribution(approved.id, 'Approved note.');
    await reviewRepository.rejectContribution(rejected.id, 'Rejected note.');
    await reviewRepository.requestChanges(changes.id, 'Clarify source.');

    final underReviewLoaded = await contributions.findContribution(
      underReview.id,
    );
    final approvedLoaded = await contributions.findContribution(approved.id);
    final rejectedLoaded = await contributions.findContribution(rejected.id);
    final changesLoaded = await contributions.findContribution(changes.id);

    expect(switch (underReviewLoaded) {
      Success<ContributionModel?>(:final value) => value?.status,
      Failure<ContributionModel?>() => null,
    }, ContributionStatus.underReview);
    expect(switch (approvedLoaded) {
      Success<ContributionModel?>(:final value) => value?.status,
      Failure<ContributionModel?>() => null,
    }, ContributionStatus.curatorApproved);
    expect(switch (approvedLoaded) {
      Success<ContributionModel?>(:final value) => value?.reviewNote,
      Failure<ContributionModel?>() => null,
    }, 'Approved note.');
    expect(switch (rejectedLoaded) {
      Success<ContributionModel?>(:final value) => value?.status,
      Failure<ContributionModel?>() => null,
    }, ContributionStatus.rejected);
    expect(switch (changesLoaded) {
      Success<ContributionModel?>(:final value) => value?.reviewNote,
      Failure<ContributionModel?>() => null,
    }, 'Changes requested: Clarify source.');
  });

  test(
    'local knowledge repository exposes approved contributions in search',
    () async {
      final contributions = LocalContributionRepository();
      final reviewRepository = LocalReviewRepository(
        contributions: contributions,
      );
      final knowledgeRepository = LocalKnowledgeRepository(
        contributions: contributions,
      );
      final contributionResult = await contributions.createContribution(
        contributionInput(title: 'Kempli pulse'),
      );
      final contribution = switch (contributionResult) {
        Success<ContributionModel>(:final value) => value,
        Failure<ContributionModel>() => fail('Expected success'),
      };

      final emptySearch = await knowledgeRepository.searchKnowledge(
        query: 'Kempli',
      );
      expect(switch (emptySearch) {
        Success<List<dynamic>>(:final value) => value,
        Failure<List<dynamic>>() => fail('Expected success'),
      }, isEmpty);

      await reviewRepository.approveContribution(
        contribution.id,
        'Curator approved.',
      );
      final resultsResult = await knowledgeRepository.searchKnowledge(
        query: 'Kempli',
      );
      final results = switch (resultsResult) {
        Success(:final value) => value,
        Failure() => fail('Expected success'),
      };

      expect(results, hasLength(1));
      expect(results.single.title, 'Kempli pulse');
      expect(results.single.isCommunityApproved, isTrue);
      expect(
        results.single.provenanceSummary,
        contains('Community approved demo content'),
      );
    },
  );
}

ContributionInput contributionInput({
  required String title,
  bool culturalSensitivity = false,
  bool submitForReview = true,
}) {
  return ContributionInput(
    title: title,
    description: 'Local practice note for repository testing.',
    knowledgeType: 'Instrument',
    gamelanType: 'Gong Kebyar',
    sourceNote: 'Contributor interview summary.',
    contributorNote: 'Repository test note.',
    culturalSensitivity: culturalSensitivity,
    consentGiven: true,
    submitForReview: submitForReview,
    contributionIntent: 'new_entity',
  );
}

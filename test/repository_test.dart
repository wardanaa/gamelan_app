import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_repository.dart';
import 'package:gamelan_app/features/review/data/review_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local contribution repository includes initial demo seed', () async {
    final repository = LocalContributionRepository();

    final contributions = await repository.fetchContributions();

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
    final contributions = await secondRepository.fetchContributions();

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
      final contributions = await secondRepository.fetchContributions();

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
      final contributions = await secondRepository.fetchContributions();

      expect(
        contributions.map((contribution) => contribution.title),
        isNot(contains('Submitted reyong note')),
      );
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
      final approved = await contributions.createContribution(
        contributionInput(title: 'Approved note'),
      );
      await reviewRepository.approveContribution(approved.id, 'Approved.');
      final underReview = await contributions.createContribution(
        contributionInput(title: 'Under-review note'),
      );
      await reviewRepository.markUnderReview(underReview.id);

      final queue = await reviewRepository.fetchReviewQueue();
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
    final underReview = await contributions.createContribution(
      contributionInput(title: 'Under review item'),
    );
    final approved = await contributions.createContribution(
      contributionInput(title: 'Approved item'),
    );
    final rejected = await contributions.createContribution(
      contributionInput(title: 'Rejected item'),
    );
    final changes = await contributions.createContribution(
      contributionInput(title: 'Changes item'),
    );

    await reviewRepository.markUnderReview(underReview.id);
    await reviewRepository.approveContribution(approved.id, 'Approved note.');
    await reviewRepository.rejectContribution(rejected.id, 'Rejected note.');
    await reviewRepository.requestChanges(changes.id, 'Clarify source.');

    expect(
      (await contributions.findContribution(underReview.id))?.status,
      ContributionStatus.underReview,
    );
    expect(
      (await contributions.findContribution(approved.id))?.status,
      ContributionStatus.approved,
    );
    expect(
      (await contributions.findContribution(approved.id))?.reviewNote,
      'Approved note.',
    );
    expect(
      (await contributions.findContribution(rejected.id))?.status,
      ContributionStatus.rejected,
    );
    expect(
      (await contributions.findContribution(rejected.id))?.reviewNote,
      'Rejected note.',
    );
    expect(
      (await contributions.findContribution(changes.id))?.reviewNote,
      'Changes requested: Clarify source.',
    );
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
      final contribution = await contributions.createContribution(
        contributionInput(title: 'Kempli pulse'),
      );

      expect(
        await knowledgeRepository.searchKnowledge(query: 'Kempli'),
        isEmpty,
      );

      await reviewRepository.approveContribution(
        contribution.id,
        'Curator approved.',
      );
      final results = await knowledgeRepository.searchKnowledge(
        query: 'Kempli',
      );

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
  );
}

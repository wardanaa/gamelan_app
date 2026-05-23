import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/state/gamelan_mvp_store.dart';
import 'package:gamelan_app/core/state/gamelan_scope.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/core/mapping/taxonomy_mapper.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/contributions/data/media_asset_model.dart';
import 'package:gamelan_app/features/contributions/screens/contribution_detail_screen.dart';
import 'package:gamelan_app/features/contributions/widgets/status_badge.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_item.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_repository.dart';
import 'package:gamelan_app/features/provenance/data/provenance_timeline_entry.dart';
import 'package:gamelan_app/features/review/data/review_repository.dart';
import 'package:gamelan_app/features/review/screens/review_detail_screen.dart';
import 'package:gamelan_app/features/review/data/triage_suggestion.dart';
import 'package:gamelan_app/features/review/widgets/expert_validation_dialog.dart';
import 'package:gamelan_app/features/review/widgets/mark_expert_required_dialog.dart';

void main() {
  testWidgets('review detail renders actions from allowed_actions', (
    WidgetTester tester,
  ) async {
    final store = _buildStore(
      contributions: [
        _reviewContribution(
          id: 'review-1',
          allowedActions: const [
            'approve',
            'reject',
            'request_revision',
            'mark_expert_required',
            'expert_validate',
          ],
          culturalSensitivity: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GamelanScope(
          store: store,
          child: const ReviewDetailScreen(contributionId: 'review-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Standard review'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Expert workflow'),
      200,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Standard review'), findsOneWidget);
    expect(find.text('Expert workflow'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Approve'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Request changes'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Reject'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Request Expert Validation'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Validate'), findsOneWidget);
  });

  testWidgets('status badges distinguish expert workflow states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              StatusBadge(status: ContributionStatus.curatorApproved),
              StatusBadge(status: ContributionStatus.expertRequired),
              StatusBadge(status: ContributionStatus.expertApproved),
            ],
          ),
        ),
      ),
    );

    final curatorBadge = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.text('Curator approved'),
        matching: find.byType(DecoratedBox),
      ),
    );
    final expertRequiredBadge = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.text('Expert required'),
        matching: find.byType(DecoratedBox),
      ),
    );
    final expertApprovedBadge = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.text('Expert approved'),
        matching: find.byType(DecoratedBox),
      ),
    );

    final curatorColor = (curatorBadge.decoration as BoxDecoration).color;
    final requiredColor =
        (expertRequiredBadge.decoration as BoxDecoration).color;
    final approvedColor =
        (expertApprovedBadge.decoration as BoxDecoration).color;

    expect(requiredColor, isNot(curatorColor));
    expect(approvedColor, isNot(curatorColor));
    expect(requiredColor, isNot(approvedColor));
  });

  testWidgets('review detail falls back when allowed_actions is absent', (
    WidgetTester tester,
  ) async {
    final store = _buildStore(
      contributions: [
        _reviewContribution(
          id: 'review-2',
          status: ContributionStatus.submitted,
          allowedActions: const [],
          culturalSensitivity: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GamelanScope(
          store: store,
          child: const ReviewDetailScreen(contributionId: 'review-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Standard review'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Request Expert Validation'),
      200,
      scrollable: find.byType(Scrollable),
    );

    expect(find.widgetWithText(FilledButton, 'Approve'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Request changes'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Reject'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Request Expert Validation'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Validate'), findsNothing);
  });

  testWidgets(
    'expert validation dialog keeps private note hidden until enabled',
    (WidgetTester tester) async {
      final reviewRepository = FakeReviewRepository();
      final store = _buildStore(
        reviewRepository: reviewRepository,
        contributions: [
          _reviewContribution(
            id: 'review-3',
            status: ContributionStatus.expertRequired,
            allowedActions: const ['expert_validate'],
          ),
        ],
      );

      await _pumpDialog(
        tester,
        store: store,
        child: const ExpertValidationDialog(contributionId: 'review-3'),
      );

      expect(find.byKey(const Key('expert_private_note_field')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('expert_public_note_field')),
        'Validated for contributor visibility.',
      );
      await tester.tap(find.byKey(const Key('expert_private_note_toggle')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('expert_private_note_field')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('expert_private_note_field')),
        'Internal context for reviewers only.',
      );
      await tester.tap(find.byKey(const Key('expert_decision_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reject').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Validate'));
      await tester.pumpAndSettle();

      expect(reviewRepository.lastExpertValidateDecision, 'reject');
      expect(
        reviewRepository.lastExpertValidatePublicNote,
        'Validated for contributor visibility.',
      );
      expect(
        reviewRepository.lastExpertValidatePrivateNote,
        'Internal context for reviewers only.',
      );
      expect(find.text('Expert validation'), findsNothing);
    },
  );

  testWidgets('mark expert required dialog validates reasons and submits', (
    WidgetTester tester,
  ) async {
    final reviewRepository = FakeReviewRepository();
    final store = _buildStore(
      reviewRepository: reviewRepository,
      contributions: [
        _reviewContribution(
          id: 'review-4',
          status: ContributionStatus.submitted,
          culturalSensitivity: true,
          allowedActions: const ['mark_expert_required'],
        ),
      ],
    );

    await _pumpDialog(
      tester,
      store: store,
      child: const MarkExpertRequiredDialog(contributionId: 'review-4'),
    );

    await tester.enterText(
      find.byKey(const Key('mark_expert_public_note_field')),
      'Needs expert cultural validation.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Select at least one reason.'), findsOneWidget);

    await tester.tap(find.text('Origin claim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Curator flagged'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      reviewRepository.lastMarkExpertRequiredNote,
      'Needs expert cultural validation.',
    );
    expect(reviewRepository.lastMarkExpertRequiredReasons, [
      'origin_claim',
      'curator_flagged',
    ]);
    expect(find.text('Request expert validation'), findsNothing);
  });

  testWidgets('expert workflow failures stay on screen and show a snackbar', (
    WidgetTester tester,
  ) async {
    final reviewRepository = FakeReviewRepository(
      expertValidateResult: const Failure(
        'You do not have permission to perform this action.',
      ),
    );
    final store = _buildStore(
      reviewRepository: reviewRepository,
      contributions: [
        _reviewContribution(
          id: 'review-5',
          status: ContributionStatus.expertRequired,
          allowedActions: const ['expert_validate'],
        ),
      ],
    );

    await _pumpDialog(
      tester,
      store: store,
      child: const ExpertValidationDialog(contributionId: 'review-5'),
    );

    await tester.enterText(
      find.byKey(const Key('expert_public_note_field')),
      'Public expert note.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Validate'));
    await tester.pumpAndSettle();

    expect(
      find.text('You do not have permission to perform this action.'),
      findsOneWidget,
    );
    expect(find.text('Expert validation'), findsOneWidget);
  });

  testWidgets('contributor-facing detail does not render review notes', (
    WidgetTester tester,
  ) async {
    final store = _buildStore(
      contributions: [
        _reviewContribution(
          id: 'review-6',
          status: ContributionStatus.submitted,
          reviewNote: 'Private reviewer context.',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GamelanScope(
          store: store,
          child: const ContributionDetailScreen(contributionId: 'review-6'),
        ),
      ),
    );

    expect(find.text('Private reviewer context.'), findsNothing);
    expect(find.text('Review note'), findsNothing);
    expect(find.text('Private note'), findsNothing);
  });

  testWidgets(
    'review detail shows triage summary while contributor detail does not',
    (WidgetTester tester) async {
      final triageSuggestion = TriageSuggestion(
        label: 'AI suggestion, not validated.',
        provider: 'rules',
        status: 'suggested',
        modelName: 'rule-based-v1',
        processedAt: DateTime(2026, 5, 23),
        confidenceScore: '0.7600',
        suggestedEntityType: 'instrument',
        suggestedRelations: const [],
        duplicateCandidates: const [],
        missingMetadata: const [],
        languageNormalization: const {'suggested_language': 'id'},
        curatorSummary: 'Extractive summary from submitted text.',
        uncertaintyNotes: const ['Human validation is still required.'],
      );
      final store = _buildStore(
        contributions: [
          _reviewContribution(
            id: 'review-7',
            status: ContributionStatus.submitted,
            triageSuggestion: triageSuggestion,
            allowedActions: const ['approve', 'reject'],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GamelanScope(
            store: store,
            child: const ReviewDetailScreen(contributionId: 'review-7'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI suggestion, not validated.'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: GamelanScope(
            store: store,
            child: const ContributionDetailScreen(contributionId: 'review-7'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI suggestion, not validated.'), findsNothing);
    },
  );
}

GamelanMvpStore _buildStore({
  List<ContributionModel> contributions = const [],
  FakeReviewRepository? reviewRepository,
}) {
  final contributionRepository = FakeContributionRepository(contributions);
  return TestReviewStore(
    contributionsById: {
      for (final contribution in contributions) contribution.id: contribution,
    },
    contributionRepository: contributionRepository,
    reviewRepository: reviewRepository ?? FakeReviewRepository(),
    knowledgeRepository: FakeKnowledgeRepository(),
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required GamelanMvpStore store,
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GamelanScope(
        store: store,
        child: _DialogHost(child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _DialogHost extends StatefulWidget {
  const _DialogHost({required this.child});

  final Widget child;

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final store = GamelanScope.of(context);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => GamelanScope(store: store, child: widget.child),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

class TestReviewStore extends GamelanMvpStore {
  TestReviewStore({
    required Map<String, ContributionModel> contributionsById,
    required super.contributionRepository,
    required super.reviewRepository,
    required super.knowledgeRepository,
  }) : _contributionsById = contributionsById;

  final Map<String, ContributionModel> _contributionsById;

  @override
  ContributionModel? contributionById(String id) {
    return _contributionsById[id] ?? super.contributionById(id);
  }
}

class FakeContributionRepository implements ContributionRepository {
  FakeContributionRepository(this._contributions);

  final List<ContributionModel> _contributions;

  @override
  Future<void> loadPersistedDrafts() async {}

  @override
  Future<Result<List<ContributionModel>>> fetchContributions() async {
    return Success(List.unmodifiable(_contributions));
  }

  @override
  Future<Result<ContributionModel?>> findContribution(String id) async {
    for (final contribution in _contributions) {
      if (contribution.id == id) {
        return Success(contribution);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<ContributionStatus, int>>> fetchStatusCounts() async {
    return Success({
      for (final status in ContributionStatus.values)
        status: _contributions.where((item) => item.status == status).length,
    });
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

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({
    this.queue = const [],
    this.approveResult = const Success(null),
    this.rejectResult = const Success(null),
    this.requestChangesResult = const Success(null),
    this.markExpertRequiredResult = const Success(null),
    this.expertValidateResult = const Success(null),
  });

  final List<ContributionModel> queue;
  final Result<void> approveResult;
  final Result<void> rejectResult;
  final Result<void> requestChangesResult;
  final Result<void> markExpertRequiredResult;
  final Result<void> expertValidateResult;

  String? lastMarkExpertRequiredNote;
  List<String> lastMarkExpertRequiredReasons = const [];
  String? lastExpertValidateDecision;
  String? lastExpertValidatePublicNote;
  String? lastExpertValidatePrivateNote;

  @override
  Future<Result<List<ContributionModel>>> fetchReviewQueue() async {
    return Success(List.unmodifiable(queue));
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
    return approveResult;
  }

  @override
  Future<Result<void>> rejectContribution(
    String contributionId,
    String note,
  ) async {
    return rejectResult;
  }

  @override
  Future<Result<void>> requestChanges(
    String contributionId,
    String note,
  ) async {
    return requestChangesResult;
  }

  @override
  Future<Result<void>> markExpertRequired(
    String contributionId,
    String note,
    List<String> reasons,
  ) async {
    lastMarkExpertRequiredNote = note;
    lastMarkExpertRequiredReasons = reasons;
    return markExpertRequiredResult;
  }

  @override
  Future<Result<void>> expertValidate(
    String contributionId,
    String decision,
    String note,
    String privateNote,
  ) async {
    lastExpertValidateDecision = decision;
    lastExpertValidatePublicNote = note;
    lastExpertValidatePrivateNote = privateNote;
    return expertValidateResult;
  }
}

class FakeKnowledgeRepository implements KnowledgeRepository {
  @override
  Future<Result<List<KnowledgeItem>>> fetchKnowledgeItems() async {
    return const Success(<KnowledgeItem>[]);
  }

  @override
  Future<Result<KnowledgeItem?>> findKnowledgeItem(String id) async {
    return const Success(null);
  }

  @override
  Future<Result<List<KnowledgeItem>>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
    String? gamelanTypeSlug,
    String? knowledgeTypeSlug,
  }) async {
    return const Success(<KnowledgeItem>[]);
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

ContributionModel _reviewContribution({
  required String id,
  ContributionStatus status = ContributionStatus.submitted,
  List<String> allowedActions = const [],
  bool culturalSensitivity = false,
  String? reviewNote,
  TriageSuggestion? triageSuggestion,
}) {
  return ContributionModel(
    id: id,
    title: 'Review title $id',
    description: 'Review description for $id',
    status: status,
    knowledgeType: 'Instrument',
    gamelanType: 'Gong Kebyar',
    sourceNote: 'Source note for $id',
    contributorNote: 'Contributor note for $id',
    culturalSensitivity: culturalSensitivity,
    consentGiven: true,
    createdAt: DateTime(2026, 5, 23),
    statusLabel: status.label,
    allowedActions: allowedActions,
    reviewNote: reviewNote,
    triageSuggestion: triageSuggestion,
  );
}

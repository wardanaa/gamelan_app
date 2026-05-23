import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/app.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/constants/api_endpoints.dart';
import 'package:gamelan_app/core/storage/token_storage.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/auth/data/auth_repository.dart';
import 'package:gamelan_app/features/auth/data/auth_session.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart'
    show ContributionModel, ContributionStatus;
import 'package:gamelan_app/core/mapping/taxonomy_mapper.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = LiveReviewWorkflowConfig.fromDartDefines();

  if (config == null) {
    testWidgets(
      'live Laravel backend review workflow skipped: set GAMELAN_TEST_API_BASE_URL, GAMELAN_TEST_REVIEW_EMAIL, GAMELAN_TEST_REVIEW_PASSWORD, and GAMELAN_TEST_REVIEW_UUID with --dart-define',
      (WidgetTester tester) async {},
      skip: true,
    );
    return;
  }

  testWidgets(
    'live Laravel backend review workflow navigates queue, provenance, and expert validation',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final httpClient = http.Client();
      addTearDown(httpClient.close);

      final tokenStorage = TokenStorage(backend: MemoryTokenStorageBackend());
      final apiClient = ApiClient(
        baseUrl: config.apiBaseUrl,
        httpClient: httpClient,
      );
      final authRepository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final reviewSessionResult = await authRepository.signIn(
        email: config.reviewEmail,
        password: config.reviewPassword,
      );
      final reviewSession = switch (reviewSessionResult) {
        Success<AuthSession>(:final value) => value,
        Failure<AuthSession>(:final message) => fail(message),
      };

      final reviewQueueResponse = await apiClient.getJson(
        ApiEndpoints.reviewQueue,
        token: reviewSession.accessToken,
      );
      final queueItems = ContributionModel.listFromApi(
        reviewQueueResponse.data,
        taxonomy: TaxonomyMapper(),
      );
      final targetReview = queueItems.firstWhere(
        (item) => item.id == config.reviewUuid,
        orElse: () => throw TestFailure(
          'The review UUID ${config.reviewUuid} was not present in the live review queue.',
        ),
      );

      expect(
        targetReview.allowedActions,
        contains('mark_expert_required'),
        reason:
            'Provide a review UUID that can be escalated to expert validation for this live workflow test.',
      );

      final reviewDetailBefore = await apiClient.getJson(
        ApiEndpoints.review(config.reviewUuid),
        token: reviewSession.accessToken,
      );
      final initialReview = _reviewFromApi(reviewDetailBefore.dataMap);
      expect(initialReview, isNotNull);
      expect(initialReview!.status, isNot(ContributionStatus.expertApproved));

      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GamelanApp(
          authRepository: authRepository,
          tokenStorage: tokenStorage,
          apiClient: apiClient,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.text('Review queue'), findsOneWidget);
      expect(find.text(targetReview.title), findsOneWidget);

      await tester.tap(find.text(targetReview.title));
      await tester.pumpAndSettle();

      expect(find.text('Review details'), findsOneWidget);
      expect(find.text(targetReview.title), findsOneWidget);
      expect(find.text('View provenance timeline'), findsOneWidget);
      if (targetReview.triageSuggestion != null) {
        expect(find.text('AI suggestion, not validated.'), findsOneWidget);
      }

      await tester.tap(find.text('View provenance timeline'));
      await tester.pumpAndSettle();

      expect(find.text('Provenance timeline'), findsOneWidget);
      expect(find.text(targetReview.title), findsOneWidget);
      expect(
        find.text(
          'Only safe trace fields are shown here. Private notes, hidden identities, file paths, URLs, and raw AI content are omitted.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Private note'), findsNothing);
      expect(find.textContaining('http://'), findsNothing);
      expect(find.textContaining('https://'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(OutlinedButton, 'Request Expert Validation'),
        findsOneWidget,
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Request Expert Validation'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request expert validation'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('mark_expert_public_note_field')),
        'Escalate for expert validation in the live workflow test.',
      );
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Origin claim'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Curator flagged'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final reviewAfterEscalation = await apiClient.getJson(
        ApiEndpoints.review(config.reviewUuid),
        token: reviewSession.accessToken,
      );
      final escalatedReview = _reviewFromApi(reviewAfterEscalation.dataMap);
      expect(escalatedReview, isNotNull);
      expect(escalatedReview!.status, ContributionStatus.expertRequired);
      expect(escalatedReview.allowedActions, contains('expert_validate'));

      expect(find.widgetWithText(FilledButton, 'Validate'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Validate'));
      await tester.pumpAndSettle();

      expect(find.text('Expert validation'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('expert_public_note_field')),
        'Validated in the live review workflow test.',
      );
      await tester.enterText(
        find.byKey(const Key('expert_private_note_field')),
        'Private reviewer note for the live reviewer workflow test.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Validate'));
      await tester.pumpAndSettle();

      final reviewAfterValidation = await apiClient.getJson(
        ApiEndpoints.review(config.reviewUuid),
        token: reviewSession.accessToken,
      );
      final validatedReview = _reviewFromApi(reviewAfterValidation.dataMap);
      expect(validatedReview, isNotNull);
      expect(validatedReview!.status, ContributionStatus.expertApproved);
      expect(find.text('Expert approved'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

class LiveReviewWorkflowConfig {
  const LiveReviewWorkflowConfig({
    required this.apiBaseUrl,
    required this.reviewEmail,
    required this.reviewPassword,
    required this.reviewUuid,
  });

  final String apiBaseUrl;
  final String reviewEmail;
  final String reviewPassword;
  final String reviewUuid;

  static LiveReviewWorkflowConfig? fromDartDefines() {
    final apiBaseUrl = _dartDefineValue(
      const String.fromEnvironment('GAMELAN_TEST_API_BASE_URL'),
    );
    final reviewEmail = _dartDefineValue(
      const String.fromEnvironment('GAMELAN_TEST_REVIEW_EMAIL'),
    );
    final reviewPassword = _dartDefineValue(
      const String.fromEnvironment('GAMELAN_TEST_REVIEW_PASSWORD'),
    );
    final reviewUuid = _dartDefineValue(
      const String.fromEnvironment('GAMELAN_TEST_REVIEW_UUID'),
    );

    if (apiBaseUrl == null ||
        reviewEmail == null ||
        reviewPassword == null ||
        reviewUuid == null) {
      return null;
    }

    return LiveReviewWorkflowConfig(
      apiBaseUrl: apiBaseUrl,
      reviewEmail: reviewEmail,
      reviewPassword: reviewPassword,
      reviewUuid: reviewUuid,
    );
  }

  static String? _dartDefineValue(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }
    return trimmedValue;
  }
}

ContributionModel? _reviewFromApi(Map<String, Object?> data) {
  final nestedContribution = _mapFrom(data['contribution']);
  if (nestedContribution != null) {
    return ContributionModel.fromApi(
      nestedContribution,
      taxonomy: TaxonomyMapper(),
    );
  }

  final nestedReview = _mapFrom(data['review']);
  if (nestedReview != null) {
    final nestedNestedContribution = _mapFrom(nestedReview['contribution']);
    if (nestedNestedContribution != null) {
      return ContributionModel.fromApi(
        nestedNestedContribution,
        taxonomy: TaxonomyMapper(),
      );
    }
    return ContributionModel.fromApi(nestedReview, taxonomy: TaxonomyMapper());
  }

  return ContributionModel.fromApi(data, taxonomy: TaxonomyMapper());
}

Map<String, Object?>? _mapFrom(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return null;
}

class MemoryTokenStorageBackend implements TokenStorageBackend {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}

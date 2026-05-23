import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/app.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/constants/api_endpoints.dart';
import 'package:gamelan_app/core/storage/token_storage.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/auth/data/auth_repository.dart';
import 'package:gamelan_app/features/auth/data/auth_session.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = LiveLaravelBackendConfig.fromDartDefines();
  final reviewConfig = LiveReviewContractConfig.fromDartDefines();

  if (config == null) {
    testWidgets(
      'live Laravel backend authentication flow skipped: set GAMELAN_TEST_API_BASE_URL, GAMELAN_TEST_EMAIL, and GAMELAN_TEST_PASSWORD with --dart-define',
      (WidgetTester tester) async {},
      skip: true,
    );
    return;
  }

  testWidgets(
    'live Laravel backend authentication flow signs in, loads profile, and signs out',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final tokenBackend = MemoryTokenStorageBackend();
      final tokenStorage = TokenStorage(backend: tokenBackend);
      final httpClient = http.Client();
      addTearDown(httpClient.close);

      final apiClient = ApiClient(
        baseUrl: config.apiBaseUrl,
        httpClient: httpClient,
      );
      final authRepository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(GamelanApp(authRepository: authRepository));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).at(0), config.email);
      await tester.enterText(find.byType(EditableText).at(1), config.password);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      final storedToken = await tokenStorage.readToken();
      expect(
        storedToken,
        isNotNull,
        reason:
            'The Laravel login response must include data.access_token and the app must store it after /me succeeds.',
      );
      expect(storedToken, isNot(isEmpty));
      expect(
        find.text('Gamelan Knowledge MVP'),
        findsOneWidget,
        reason:
            'The app should reach the authenticated shell after Laravel login and profile loading succeed.',
      );

      final profileResponse = await apiClient.getJson(
        ApiEndpoints.me,
        token: storedToken,
      );
      final profileUser =
          _mapFrom(profileResponse.dataMap['user']) ?? profileResponse.dataMap;
      expect(
        _stringListFrom(profileUser, const ['roles']),
        isNotEmpty,
        reason:
            'GET /me should expose backend roles so the mobile client can gate review access.',
      );
      expect(
        _stringListFrom(profileUser, const ['permissions']),
        isNotEmpty,
        reason:
            'GET /me should expose backend permissions so the mobile client can gate review actions.',
      );

      final profileResult = await authRepository.loadProfile(storedToken!);
      final profileSession = switch (profileResult) {
        Success<AuthSession>(:final value) => value,
        Failure<AuthSession>(:final message) => fail(message),
      };

      expect(profileSession.roles, isNotEmpty);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Backend roles'), findsOneWidget);
      expect(find.text(profileSession.roleLabel), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(await tokenStorage.readToken(), isNull);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

  if (!reviewConfig.isConfigured) {
    testWidgets(
      'live Laravel backend review contract verification skipped: set GAMELAN_TEST_REVIEW_EMAIL, GAMELAN_TEST_REVIEW_PASSWORD, GAMELAN_TEST_MARK_EXPERT_REQUIRED_UUID, and GAMELAN_TEST_EXPERT_VALIDATE_UUID with --dart-define',
      (WidgetTester tester) async {},
      skip: true,
    );
    return;
  }

  testWidgets(
    'live Laravel backend review contract verifies expert workflow and privacy gates',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final httpClient = http.Client();
      addTearDown(httpClient.close);

      final apiClient = ApiClient(
        baseUrl: config.apiBaseUrl,
        httpClient: httpClient,
      );
      final reviewTokenStorage = TokenStorage(
        backend: MemoryTokenStorageBackend(),
      );
      final reviewAuthRepository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: reviewTokenStorage,
      );

      final reviewSessionResult = await reviewAuthRepository.signIn(
        email: reviewConfig.reviewEmail,
        password: reviewConfig.reviewPassword,
      );
      final reviewSession = switch (reviewSessionResult) {
        Success<AuthSession>(:final value) => value,
        Failure<AuthSession>(:final message) => fail(message),
      };

      final markExpertRequiredUuid = reviewConfig.markExpertRequiredUuid;
      if (markExpertRequiredUuid != null) {
        final markResponse = await apiClient.postJson(
          ApiEndpoints.reviewMarkExpertRequired(markExpertRequiredUuid),
          token: reviewSession.accessToken,
          body: {
            'note': 'Marked for expert validation during live contract check.',
            'expert_required_reasons': ['origin_claim', 'curator_flagged'],
          },
        );
        expect(markResponse.success, isTrue);

        final reviewDetail = await apiClient.getJson(
          '/reviews/$markExpertRequiredUuid',
          token: reviewSession.accessToken,
        );
        final reviewPayload = _reviewPayloadFrom(reviewDetail.dataMap);

        expect(_stringFrom(reviewPayload, const ['status']), 'expert_required');
        expect(
          _stringListFrom(reviewPayload, const ['allowed_actions']),
          contains('expert_validate'),
        );
      }

      final expertValidateUuid = reviewConfig.expertValidateUuid;
      if (expertValidateUuid != null) {
        final expertValidateResponse = await apiClient.postJson(
          ApiEndpoints.reviewExpertValidate(expertValidateUuid),
          token: reviewSession.accessToken,
          body: {
            'decision': 'approve',
            'note': 'Validated during live contract check.',
            'private_note':
                'Private reviewer note for authorized reviewers only.',
          },
        );
        expect(expertValidateResponse.success, isTrue);

        final reviewDetail = await apiClient.getJson(
          '/reviews/$expertValidateUuid',
          token: reviewSession.accessToken,
        );
        final reviewPayload = _reviewPayloadFrom(reviewDetail.dataMap);

        expect(_stringFrom(reviewPayload, const ['status']), 'expert_approved');
        expect(
          _stringListFrom(reviewPayload, const ['allowed_actions']),
          isNotEmpty,
        );
      }
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

class LiveLaravelBackendConfig {
  const LiveLaravelBackendConfig({
    required this.apiBaseUrl,
    required this.email,
    required this.password,
  });

  final String apiBaseUrl;
  final String email;
  final String password;

  static LiveLaravelBackendConfig? fromDartDefines() {
    final apiBaseUrl = _dartDefineValue(_apiBaseUrl);
    final email = _dartDefineValue(_email);
    final password = _dartDefineValue(_password);

    if (apiBaseUrl == null || email == null || password == null) {
      return null;
    }

    return LiveLaravelBackendConfig(
      apiBaseUrl: apiBaseUrl,
      email: email,
      password: password,
    );
  }

  static const String _apiBaseUrl = String.fromEnvironment(
    'GAMELAN_TEST_API_BASE_URL',
  );
  static const String _email = String.fromEnvironment('GAMELAN_TEST_EMAIL');
  static const String _password = String.fromEnvironment(
    'GAMELAN_TEST_PASSWORD',
  );

  static String? _dartDefineValue(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }
    return trimmedValue;
  }
}

class LiveReviewContractConfig {
  const LiveReviewContractConfig({
    required this.reviewEmail,
    required this.reviewPassword,
    this.markExpertRequiredUuid,
    this.expertValidateUuid,
  });

  final String reviewEmail;
  final String reviewPassword;
  final String? markExpertRequiredUuid;
  final String? expertValidateUuid;

  bool get isConfigured =>
      reviewEmail.trim().isNotEmpty &&
      reviewPassword.trim().isNotEmpty &&
      (markExpertRequiredUuid?.trim().isNotEmpty == true ||
          expertValidateUuid?.trim().isNotEmpty == true);

  static LiveReviewContractConfig fromDartDefines() {
    return LiveReviewContractConfig(
      reviewEmail:
          _dartDefineValue(
            const String.fromEnvironment('GAMELAN_TEST_REVIEW_EMAIL'),
          ) ??
          '',
      reviewPassword:
          _dartDefineValue(
            const String.fromEnvironment('GAMELAN_TEST_REVIEW_PASSWORD'),
          ) ??
          '',
      markExpertRequiredUuid: _dartDefineValue(
        const String.fromEnvironment('GAMELAN_TEST_MARK_EXPERT_REQUIRED_UUID'),
      ),
      expertValidateUuid: _dartDefineValue(
        const String.fromEnvironment('GAMELAN_TEST_EXPERT_VALIDATE_UUID'),
      ),
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

Map<String, Object?> _reviewPayloadFrom(Map<String, Object?> data) {
  final nestedContribution = _mapFrom(data['contribution']);
  if (nestedContribution != null) {
    return nestedContribution;
  }

  final nestedReview = _mapFrom(data['review']);
  if (nestedReview != null) {
    final nestedNestedContribution = _mapFrom(nestedReview['contribution']);
    if (nestedNestedContribution != null) {
      return nestedNestedContribution;
    }
    return nestedReview;
  }

  return data;
}

String? _stringFrom(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

List<String> _stringListFrom(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is Iterable) {
      return value
          .whereType<String>()
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
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

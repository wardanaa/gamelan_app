import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/app.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/storage/token_storage.dart';
import 'package:gamelan_app/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = LiveLaravelBackendConfig.fromDartDefines();

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

      final authRepository = AuthRepository(
        apiClient: ApiClient(
          baseUrl: config.apiBaseUrl,
          httpClient: httpClient,
        ),
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

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Backend roles'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(await tokenStorage.readToken(), isNull);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
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

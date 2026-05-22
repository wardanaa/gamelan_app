import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/state/gamelan_mvp_store.dart';
import 'package:gamelan_app/core/storage/token_storage.dart';
import 'package:gamelan_app/app.dart';
import 'package:gamelan_app/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<MemoryTokenStorageBackend> pumpMvpApp(
    WidgetTester tester, {
    bool resetPreferences = true,
    bool authenticated = true,
    http.Client? httpClient,
  }) async {
    if (resetPreferences) {
      SharedPreferences.setMockInitialValues({});
    }
    final tokenBackend = MemoryTokenStorageBackend();
    final tokenStorage = TokenStorage(backend: tokenBackend);
    if (authenticated) {
      await tokenStorage.saveToken('saved-test-token');
    }
    final authRepository = AuthRepository(
      apiClient: ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: httpClient ?? successClient(),
      ),
      tokenStorage: tokenStorage,
    );
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GamelanApp(
        authRepository: authRepository,
        store: GamelanMvpStore.local(),
      ),
    );
    await tester.pumpAndSettle();
    return tokenBackend;
  }

  Future<void> fillRequiredContributionFields(
    WidgetTester tester, {
    required String title,
  }) async {
    await tester.enterText(find.byType(EditableText).at(0), title);
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Local practice note for a non-authoritative contribution draft.',
    );
    await tester.enterText(
      find.byType(EditableText).at(2),
      'Contributor interview summary.',
    );
    await tester.enterText(
      find.byType(EditableText).at(3),
      'Contributor context note for curator review.',
    );
    await tester.tap(find.text('Contributor consent confirmed'));
    await tester.pumpAndSettle();
  }

  test('token storage saves, reads, and clears through its backend', () async {
    final backend = MemoryTokenStorageBackend();
    final storage = TokenStorage(backend: backend);

    await storage.saveToken('secure-test-token');
    expect(await storage.readToken(), 'secure-test-token');

    await storage.clearToken();
    expect(await storage.readToken(), isNull);
  });

  testWidgets('successful login stores token and opens app shell', (
    WidgetTester tester,
  ) async {
    var profileCalled = false;
    final backend = await pumpMvpApp(
      tester,
      authenticated: false,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return jsonResponse({
            'success': true,
            'message': 'Logged in.',
            'data': {
              'access_token': 'new-access-token',
              'user': {'name': 'Curator User', 'email': 'curator@example.com'},
            },
          });
        }
        if (request.url.path.endsWith('/me')) {
          profileCalled = true;
          expect(request.headers['authorization'], 'Bearer new-access-token');
          return profileResponse(
            name: 'Curator Profile',
            email: 'curator@example.com',
            roles: ['curator'],
          );
        }
        return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
      }),
    );

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).at(0),
      'curator@example.com',
    );
    await tester.enterText(find.byType(EditableText).at(1), 'secret-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      await TokenStorage(backend: backend).readToken(),
      'new-access-token',
    );
    expect(profileCalled, isTrue);
    expect(find.text('Gamelan Knowledge MVP'), findsOneWidget);
    expect(find.text('Curator Profile'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Curator Profile'), findsOneWidget);
    expect(find.text('curator'), findsOneWidget);
  });

  testWidgets('successful registration stores token after profile loading', (
    WidgetTester tester,
  ) async {
    var registerCalled = false;
    var profileCalled = false;
    final backend = await pumpMvpApp(
      tester,
      authenticated: false,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/register')) {
          registerCalled = true;
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['name'], 'New Contributor');
          expect(body['email'], 'new@example.com');
          return jsonResponse({
            'success': true,
            'message': 'Registered.',
            'data': {'access_token': 'registered-access-token'},
          });
        }
        if (request.url.path.endsWith('/me')) {
          profileCalled = true;
          expect(
            request.headers['authorization'],
            'Bearer registered-access-token',
          );
          return profileResponse(
            name: 'New Contributor',
            email: 'new@example.com',
            roles: ['contributor'],
          );
        }
        return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
      }),
    );

    await tester.tap(find.text('Need an account? Create one'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'New Contributor');
    await tester.enterText(find.byType(EditableText).at(1), 'new@example.com');
    await tester.enterText(find.byType(EditableText).at(2), 'secret-password');
    await tester.enterText(find.byType(EditableText).at(3), 'secret-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(registerCalled, isTrue);
    expect(profileCalled, isTrue);
    expect(
      await TokenStorage(backend: backend).readToken(),
      'registered-access-token',
    );
    expect(find.text('Gamelan Knowledge MVP'), findsOneWidget);
  });

  testWidgets('failed login does not store token', (WidgetTester tester) async {
    final backend = await pumpMvpApp(
      tester,
      authenticated: false,
      httpClient: MockClient((request) async {
        return jsonResponse({
          'success': false,
          'message': 'Invalid credentials.',
          'errors': {},
        }, 401);
      }),
    );

    await tester.enterText(
      find.byType(EditableText).at(0),
      'curator@example.com',
    );
    await tester.enterText(find.byType(EditableText).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(await TokenStorage(backend: backend).readToken(), isNull);
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(find.text('Gamelan Knowledge MVP'), findsNothing);
  });

  testWidgets('logout clears stored token and returns to login', (
    WidgetTester tester,
  ) async {
    var logoutCalled = false;
    final backend = await pumpMvpApp(
      tester,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          return profileResponse(roles: ['curator']);
        }
        if (request.url.path.endsWith('/auth/logout')) {
          logoutCalled = true;
          expect(request.headers['authorization'], 'Bearer saved-test-token');
          return jsonResponse({'success': true, 'message': 'Logged out.'});
        }
        return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
      }),
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(logoutCalled, isTrue);
    expect(await TokenStorage(backend: backend).readToken(), isNull);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('stored token skips login on startup', (
    WidgetTester tester,
  ) async {
    var profileCalled = false;
    await pumpMvpApp(
      tester,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          profileCalled = true;
          expect(request.headers['authorization'], 'Bearer saved-test-token');
          return profileResponse(
            name: 'Saved Curator',
            email: 'saved@example.com',
            roles: ['curator'],
          );
        }
        return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
      }),
    );

    expect(profileCalled, isTrue);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing);
    expect(find.text('Gamelan Knowledge MVP'), findsOneWidget);
  });

  testWidgets(
    'expired stored token is cleared when profile loading returns 401',
    (WidgetTester tester) async {
      final backend = await pumpMvpApp(
        tester,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/me')) {
            return jsonResponse({
              'success': false,
              'message': 'Unauthenticated.',
            }, 401);
          }
          return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
        }),
      );

      expect(await TokenStorage(backend: backend).readToken(), isNull);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    },
  );

  testWidgets('non-reviewer profile cannot access local review queue', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(
      tester,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          return profileResponse(roles: ['contributor']);
        }
        return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
      }),
    );

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review access is protected'), findsOneWidget);
    expect(find.text('Review queue'), findsNothing);
  });

  testWidgets('curator profile can access local review queue', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review queue'), findsOneWidget);
    expect(find.text('Review access is protected'), findsNothing);
  });

  testWidgets('renders the MVP app shell and seeded knowledge', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    expect(find.text('Gamelan Knowledge MVP'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Contribute'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search knowledge'), findsOneWidget);
    expect(find.text('Gong Kebyar'), findsWidgets);
    expect(find.text('Gong Gede'), findsWidgets);
    expect(find.text('Gangsa'), findsOneWidget);
  });

  testWidgets('validates contribution form and submits to review queue', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contributor consent confirmed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Complete the required fields before submitting for review.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(EditableText).at(0), 'Kajar cue note');
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Kajar helps keep a steady pulse in this local practice note.',
    );
    await tester.enterText(
      find.byType(EditableText).at(2),
      'Contributor interview summary.',
    );
    await tester.enterText(
      find.byType(EditableText).at(3),
      'Contributor context note for curator review.',
    );

    await tester.tap(find.text('Culturally sensitive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(find.text('New contribution'), findsWidgets);

    await tester.tap(find.byIcon(Icons.fact_check_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Kajar cue note'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsWidgets);
  });

  testWidgets('persists non-sensitive local drafts across app recreation', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(
      tester,
      title: 'Persistent gangsa draft',
    );
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Persistent gangsa draft'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpMvpApp(tester, resetPreferences: false);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    expect(find.text('Persistent gangsa draft'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
  });

  testWidgets('does not persist culturally sensitive local drafts', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(
      tester,
      title: 'Sensitive ceremony draft',
    );
    await tester.tap(find.text('Culturally sensitive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Sensitive ceremony draft'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpMvpApp(tester, resetPreferences: false);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    expect(find.text('Sensitive ceremony draft'), findsNothing);
  });

  testWidgets('does not persist submitted local contributions as drafts', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(
      tester,
      title: 'Submitted reyong note',
    );
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted reyong note'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted reyong note'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpMvpApp(tester, resetPreferences: false);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted reyong note'), findsNothing);
  });

  testWidgets('approved contribution becomes searchable knowledge', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Kempli pulse');
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Kempli can mark the pulse in ensemble contexts.',
    );
    await tester.enterText(
      find.byType(EditableText).at(2),
      'Local lesson note.',
    );
    await tester.tap(find.text('Contributor consent confirmed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kempli pulse'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).first,
      'Curator approved.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Kempli pulse'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsWidgets);
  });
}

class MemoryTokenStorageBackend implements TokenStorageBackend {
  MemoryTokenStorageBackend([Map<String, String>? initialValues])
    : _values = {...?initialValues};

  final Map<String, String> _values;

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

MockClient successClient() {
  return MockClient((request) async {
    if (request.url.path.endsWith('/me')) {
      return profileResponse(roles: ['curator']);
    }
    return jsonResponse({'success': true, 'message': 'OK.', 'data': {}});
  });
}

http.Response profileResponse({
  String name = 'Curator User',
  String email = 'curator@example.com',
  List<String> roles = const ['curator'],
  List<String> permissions = const [],
}) {
  return jsonResponse({
    'success': true,
    'message': 'Profile loaded.',
    'data': {
      'user': {
        'name': name,
        'email': email,
        'roles': roles,
        'permissions': permissions,
      },
    },
  });
}

http.Response jsonResponse(Map<String, Object?> body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/api/repository_errors.dart';
import 'package:gamelan_app/core/mapping/taxonomy_mapper.dart';
import 'package:gamelan_app/core/state/gamelan_mvp_store.dart';
import 'package:gamelan_app/core/state/gamelan_scope.dart';
import 'package:gamelan_app/core/storage/token_storage.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/app.dart';
import 'package:gamelan_app/features/admin/data/admin_repository.dart';
import 'package:gamelan_app/features/admin/data/admin_user_summary.dart';
import 'package:gamelan_app/features/admin/data/audit_log_entry.dart';
import 'package:gamelan_app/features/admin/screens/audit_log_screen.dart';
import 'package:gamelan_app/features/admin/screens/user_management_screen.dart';
import 'package:gamelan_app/features/auth/data/auth_repository.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/contributions/data/media_asset_model.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_item.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_repository.dart';
import 'package:gamelan_app/features/knowledge/data/local_knowledge_repository.dart';
import 'package:gamelan_app/features/review/data/review_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<MemoryTokenStorageBackend> pumpMvpApp(
    WidgetTester tester, {
    bool resetPreferences = true,
    bool authenticated = true,
    http.Client? httpClient,
    GamelanMvpStore? store,
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
        store: store ?? GamelanMvpStore.local(),
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

  GamelanMvpStore adminTestStore({AdminRepository? adminRepository}) {
    final contributions = LocalContributionRepository();
    return GamelanMvpStore(
      contributionRepository: contributions,
      reviewRepository: LocalReviewRepository(contributions: contributions),
      knowledgeRepository: LocalKnowledgeRepository(
        contributions: contributions,
      ),
      adminRepository: adminRepository ?? LocalAdminRepository(),
    );
  }

  Future<void> pumpAdminWidget(
    WidgetTester tester,
    Widget screen, {
    AdminRepository? adminRepository,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      GamelanScope(
        store: adminTestStore(adminRepository: adminRepository),
        child: MaterialApp(home: screen),
      ),
    );
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

  testWidgets('admin profile can open admin tools from profile', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(
      tester,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          return profileResponse(roles: ['admin']);
        }
        return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
      }),
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Admin tools'), findsOneWidget);

    await tester.tap(find.text('Admin tools'));
    await tester.pumpAndSettle();

    expect(find.text('Backend admin'), findsOneWidget);
    expect(find.text('User management'), findsOneWidget);
    expect(find.text('Audit logs'), findsOneWidget);
  });

  testWidgets('non-admin profile does not show admin tools', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(
      tester,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          return profileResponse(roles: ['curator']);
        }
        return jsonResponse({'success': false, 'message': 'Not found.'}, 404);
      }),
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Admin tools'), findsNothing);
  });

  testWidgets('user management screen shows loading and populated users', (
    WidgetTester tester,
  ) async {
    final repository = _CompletingAdminRepository(
      users: [
        const AdminUserSummary(
          id: 'admin-1',
          displayName: 'Made Admin',
          email: 'admin@example.com',
          roles: ['admin'],
          permissions: ['admin.users.view'],
          statusLabel: 'Active',
        ),
      ],
    );

    await pumpAdminWidget(
      tester,
      const UserManagementScreen(),
      adminRepository: repository,
    );
    await tester.pump();

    expect(find.text('Loading users'), findsOneWidget);

    repository.completeUsers();
    await tester.pumpAndSettle();

    expect(find.text('Made Admin'), findsOneWidget);
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('Roles: admin'), findsOneWidget);
    expect(find.text('1 permission'), findsOneWidget);
  });

  testWidgets('user management screen handles empty and search states', (
    WidgetTester tester,
  ) async {
    await pumpAdminWidget(
      tester,
      const UserManagementScreen(),
      adminRepository: LocalAdminRepository(users: const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('No users returned'), findsOneWidget);

    await pumpAdminWidget(
      tester,
      const UserManagementScreen(),
      adminRepository: LocalAdminRepository(
        users: const [
          AdminUserSummary(
            id: 'admin-1',
            displayName: 'Made Admin',
            email: 'admin@example.com',
            roles: ['admin'],
            statusLabel: 'Active',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();

    expect(find.text('No matching users'), findsOneWidget);
  });

  testWidgets('user management screen handles backend denial', (
    WidgetTester tester,
  ) async {
    await pumpAdminWidget(
      tester,
      const UserManagementScreen(),
      adminRepository: const _FailingAdminRepository(
        userMessage: 'Only admins can view users.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin users unavailable'), findsOneWidget);
    expect(find.text('Only admins can view users.'), findsOneWidget);
  });

  testWidgets('audit log screen shows actor-withheld audit entries', (
    WidgetTester tester,
  ) async {
    await pumpAdminWidget(
      tester,
      const AuditLogScreen(),
      adminRepository: LocalAdminRepository(
        auditLogs: const [
          AuditLogEntry(
            id: 'audit-1',
            eventType: 'admin_viewed_users',
            summary: 'Admin user list viewed.',
            targetType: 'User',
            targetId: '1',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin user list viewed.'), findsOneWidget);
    expect(find.text('Actor: Actor withheld by backend'), findsOneWidget);
    expect(find.text('Target: User 1'), findsOneWidget);
  });

  testWidgets('audit log screen handles empty and error states', (
    WidgetTester tester,
  ) async {
    await pumpAdminWidget(
      tester,
      const AuditLogScreen(),
      adminRepository: LocalAdminRepository(auditLogs: const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('No audit logs returned'), findsOneWidget);

    await pumpAdminWidget(
      tester,
      const AuditLogScreen(),
      adminRepository: const _FailingAdminRepository(
        auditMessage: 'Only admins can view audit logs.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audit logs unavailable'), findsOneWidget);
    expect(find.text('Only admins can view audit logs.'), findsOneWidget);
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

  testWidgets('search tab shows semantic fallback notice with keyword results', (
    WidgetTester tester,
  ) async {
    final contributions = LocalContributionRepository();
    final store = GamelanMvpStore(
      contributionRepository: contributions,
      reviewRepository: LocalReviewRepository(contributions: contributions),
      knowledgeRepository: _FallbackKnowledgeRepository(),
    );

    await pumpMvpApp(tester, store: store);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'gangsa');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Semantic search is temporarily unavailable. Showing keyword results instead.',
      ),
      findsOneWidget,
    );
    expect(find.text('Gangsa keyword result'), findsOneWidget);
    expect(find.text('1 knowledge items'), findsOneWidget);
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
      find.text('Complete the required fields before submitting for review.'),
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

  testWidgets('draft contribution detail shows editable media section', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(tester, title: 'Draft media note');
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft media note'));
    await tester.pumpAndSettle();

    expect(find.text('Media attachments'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Add media'), findsOneWidget);
    expect(find.text('No media attachments yet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Add media'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Upload media'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a file to upload.'), findsOneWidget);
  });

  testWidgets('needs-revision contribution can be edited and resubmitted', (
    WidgetTester tester,
  ) async {
    final contributions = LocalContributionRepository();
    final reviewRepository = LocalReviewRepository(
      contributions: contributions,
    );
    final contributionResult = await contributions.createContribution(
      contributionInput(title: 'Needs revision media note'),
    );
    final contribution = switch (contributionResult) {
      Success<ContributionModel>(:final value) => value,
      Failure<ContributionModel>() => fail('Expected success'),
    };
    await reviewRepository.requestChanges(
      contribution.id,
      'Clarify the source before resubmission.',
    );
    final store = GamelanMvpStore(
      contributionRepository: contributions,
      reviewRepository: reviewRepository,
      knowledgeRepository: LocalKnowledgeRepository(
        contributions: contributions,
      ),
    );

    await pumpMvpApp(tester, store: store);
    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Needs revision media note'));
    await tester.pumpAndSettle();

    expect(find.text('Needs revision'), findsOneWidget);
    expect(find.text('Review guidance'), findsOneWidget);
    expect(
      find.text('Changes requested: Clarify the source before resubmission.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Add media'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Edit contribution'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Submit for review'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Edit contribution'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit contribution'));
    await tester.pumpAndSettle();

    expect(find.text('Edit contribution'), findsOneWidget);
    expect(find.text('Needs revision media note'), findsOneWidget);
    expect(find.text('Review guidance'), findsOneWidget);
    expect(
      find.text('Changes requested: Clarify the source before resubmission.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(EditableText).at(0),
      'Revised needs revision note',
    );
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Save changes'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Revised needs revision note'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Edit contribution'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Edit contribution'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit contribution'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).at(0),
      'Resubmitted needs revision note',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Save and submit for review'),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Save and submit for review'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resubmitted needs revision note'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Add media'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'Edit contribution'),
      findsNothing,
    );
    expect(
      find.widgetWithText(FilledButton, 'Submit for review'),
      findsNothing,
    );
  });

  testWidgets('stale contribution edit shows conflict message', (
    WidgetTester tester,
  ) async {
    final contributions = _ConflictContributionRepository();
    final contributionResult = await contributions.createContribution(
      contributionInput(title: 'Conflicting revision note'),
    );
    final contribution = switch (contributionResult) {
      Success<ContributionModel>(:final value) => value,
      Failure<ContributionModel>() => fail('Expected success'),
    };
    await contributions.updateContributionStatus(
      contribution.id,
      ContributionStatus.needsRevision,
      reviewNote: 'Clarify the source.',
    );
    final store = GamelanMvpStore(
      contributionRepository: contributions,
      reviewRepository: LocalReviewRepository(contributions: contributions),
      knowledgeRepository: LocalKnowledgeRepository(
        contributions: contributions,
      ),
    );

    await pumpMvpApp(tester, store: store);
    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conflicting revision note'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Edit contribution'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit contribution'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(EditableText).at(0),
      'Locally revised stale note',
    );
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Save changes'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This contribution has changed since you last loaded it. Please refresh and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Edit contribution'), findsOneWidget);
  });

  testWidgets('submitted contribution hides media management actions', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(tester, title: 'Submitted media note');
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submitted media note'));
    await tester.pumpAndSettle();

    expect(find.text('Media attachments'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Add media'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'Edit contribution'),
      findsNothing,
    );
  });

  testWidgets('review detail shows read-only media metadata', (
    WidgetTester tester,
  ) async {
    final contributions = LocalContributionRepository();
    final draftResult = await contributions.createContribution(
      contributionInput(title: 'Review media note', submitForReview: false),
    );
    final draft = switch (draftResult) {
      Success<ContributionModel>(:final value) => value,
      Failure<ContributionModel>() => fail('Expected success'),
    };
    await contributions.uploadMedia(
      draft.id,
      const MediaUploadInput(
        title: 'Gangsa photo',
        mediaType: MediaType.image,
        consentStatus: MediaConsentStatus.granted,
        visibility: MediaVisibility.private,
        culturalSensitivity: false,
        filename: 'gangsa.jpg',
        altText: 'Gangsa instrument documentation.',
      ),
    );
    await contributions.submitContribution(draft.id);
    final store = GamelanMvpStore(
      contributionRepository: contributions,
      reviewRepository: LocalReviewRepository(contributions: contributions),
      knowledgeRepository: LocalKnowledgeRepository(
        contributions: contributions,
      ),
    );

    await pumpMvpApp(tester, store: store);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review media note'));
    await tester.pumpAndSettle();

    expect(find.text('Media evidence'), findsOneWidget);
    expect(find.text('Gangsa photo'), findsOneWidget);
    expect(find.textContaining('Alt text: Gangsa instrument'), findsOneWidget);
    expect(find.byTooltip('Remove media'), findsNothing);
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

ContributionInput contributionInput({
  required String title,
  bool submitForReview = true,
}) {
  return ContributionInput(
    title: title,
    description: 'Local practice note for widget testing.',
    knowledgeType: 'Instrument',
    gamelanType: 'Gong Kebyar',
    sourceNote: 'Contributor interview summary.',
    contributorNote: 'Widget test note.',
    culturalSensitivity: false,
    consentGiven: true,
    submitForReview: submitForReview,
    contributionIntent: 'new_entity',
  );
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

class _ConflictContributionRepository extends LocalContributionRepository {
  static const _message =
      'This contribution has changed since you last loaded it. Please refresh and try again.';

  @override
  Future<Result<ContributionModel>> updateContribution(
    String id,
    ContributionInput input, {
    DateTime? lastKnownUpdatedAt,
  }) async {
    return const Failure(
      _message,
      exception: RepositoryConflictException(message: _message),
    );
  }
}

class _FallbackKnowledgeRepository implements KnowledgeRepository {
  static const _item = KnowledgeItem(
    id: 'gangsa-keyword',
    title: 'Gangsa keyword result',
    description: 'Fallback keyword result from a published knowledge item.',
    knowledgeType: 'Instrument',
    gamelanType: 'Gong Kebyar',
    relations: ['usedInEnsemble: Gong Kebyar'],
    sourceSummary: 'Published safe summary.',
    provenanceSummary: 'Published backend knowledge.',
  );

  @override
  Future<Result<List<KnowledgeItem>>> fetchKnowledgeItems() async {
    return const Success(<KnowledgeItem>[]);
  }

  @override
  Future<Result<KnowledgeItem?>> findKnowledgeItem(String id) async {
    return Success(id == _item.id ? _item : null);
  }

  @override
  Future<Result<KnowledgeSearchResult>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
    String? gamelanTypeSlug,
    String? knowledgeTypeSlug,
  }) async {
    return Success(
      KnowledgeSearchResult.semanticFallback(
        const [_item],
        notice:
            'Semantic search is temporarily unavailable. Showing keyword results instead.',
      ),
    );
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchKnowledgeTypes() async {
    return const Success(TaxonomyMapper.defaultKnowledgeTypes);
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchGamelanTypes() async {
    return const Success(TaxonomyMapper.defaultGamelanTypes);
  }
}

class _CompletingAdminRepository implements AdminRepository {
  _CompletingAdminRepository({this.users = const []});

  final List<AdminUserSummary> users;
  final _usersCompleter = Completer<Result<List<AdminUserSummary>>>();

  @override
  Future<Result<List<AuditLogEntry>>> fetchAuditLogs() async {
    return const Success(<AuditLogEntry>[]);
  }

  @override
  Future<Result<List<AdminUserSummary>>> fetchUsers() {
    return _usersCompleter.future;
  }

  void completeUsers() {
    if (!_usersCompleter.isCompleted) {
      _usersCompleter.complete(Success(users));
    }
  }
}

class _FailingAdminRepository implements AdminRepository {
  const _FailingAdminRepository({
    this.userMessage = 'Admin users unavailable.',
    this.auditMessage = 'Audit logs unavailable.',
  });

  final String userMessage;
  final String auditMessage;

  @override
  Future<Result<List<AuditLogEntry>>> fetchAuditLogs() async {
    return Failure(auditMessage);
  }

  @override
  Future<Result<List<AdminUserSummary>>> fetchUsers() async {
    return Failure(userMessage);
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

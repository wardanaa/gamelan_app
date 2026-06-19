import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/state/gamelan_mvp_store.dart';
import 'core/state/gamelan_scope.dart';
import 'core/storage/token_storage.dart';
import 'core/utils/result.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_session.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/data/remote_admin_repository.dart';
import 'features/admin/screens/admin_tools_screen.dart';
import 'features/contributions/data/contribution_model.dart';
import 'features/contributions/data/remote_contribution_repository.dart';
import 'features/contributions/screens/contribution_list_screen.dart';
import 'features/contributions/widgets/status_badge.dart';
import 'features/knowledge/data/remote_knowledge_repository.dart';
import 'features/knowledge/screens/entity_list_screen.dart';
import 'features/ontology/data/remote_ontology_repository.dart';
import 'features/review/data/remote_review_repository.dart';
import 'features/review/screens/review_queue_screen.dart';

class GamelanApp extends StatefulWidget {
  const GamelanApp({
    super.key,
    AuthRepository? authRepository,
    GamelanMvpStore? store,
    TokenStorage? tokenStorage,
    ApiClient? apiClient,
  }) : _authRepository = authRepository,
       _store = store,
       _tokenStorage = tokenStorage,
       _apiClient = apiClient;

  final AuthRepository? _authRepository;
  final GamelanMvpStore? _store;
  final TokenStorage? _tokenStorage;
  final ApiClient? _apiClient;

  @override
  State<GamelanApp> createState() => _GamelanAppState();
}

class _GamelanAppState extends State<GamelanApp> {
  late final TokenStorage _tokenStorage =
      widget._tokenStorage ?? const TokenStorage();
  late final ApiClient _apiClient =
      widget._apiClient ?? ApiClient.fromEnvironment();
  late final GamelanMvpStore _store = widget._store ?? _createRemoteStore();
  late final AuthRepository _authRepository =
      widget._authRepository ??
      AuthRepository(apiClient: _apiClient, tokenStorage: _tokenStorage);

  AuthSession? _authSession;
  bool _isRestoringSession = true;

  GamelanMvpStore _createRemoteStore() {
    return GamelanMvpStore(
      contributionRepository: RemoteContributionRepository(
        apiClient: _apiClient,
        tokenResolver: _tokenStorage.readToken,
      ),
      reviewRepository: RemoteReviewRepository(
        apiClient: _apiClient,
        tokenResolver: _tokenStorage.readToken,
      ),
      knowledgeRepository: RemoteKnowledgeRepository(
        apiClient: _apiClient,
        tokenResolver: _tokenStorage.readToken,
      ),
      adminRepository: RemoteAdminRepository(
        apiClient: _apiClient,
        tokenResolver: _tokenStorage.readToken,
      ),
      ontologyRepository: RemoteOntologyRepository(
        apiClient: _apiClient,
        tokenResolver: _tokenStorage.readToken,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_restoreAuthSession());
  }

  @override
  Widget build(BuildContext context) {
    return GamelanScope(
      store: _store,
      child: MaterialApp(
        title: 'Gamelan Knowledge MVP',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (_isRestoringSession) {
      return const _AuthLoadingScreen();
    }

    final authSession = _authSession;
    if (authSession == null) {
      return LoginScreen(
        authRepository: _authRepository,
        onSignedIn: (session) {
          setState(() {
            _authSession = session;
          });
          unawaited(_store.loadRepositoryState());
        },
      );
    }

    return GamelanHomeShell(authSession: authSession, onSignOut: _signOut);
  }

  Future<void> _restoreAuthSession() async {
    final result = await _authRepository.restoreSession();
    if (!mounted) {
      return;
    }

    final session = switch (result) {
      Success<AuthSession>(:final value) => value,
      Failure<AuthSession>() => null,
    };
    setState(() {
      _authSession = session;
      _isRestoringSession = false;
    });
    if (session != null) {
      unawaited(_store.loadRepositoryState());
    }
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
    if (!mounted) {
      return;
    }

    setState(() {
      _authSession = null;
    });
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class GamelanHomeShell extends StatefulWidget {
  const GamelanHomeShell({
    super.key,
    required this.authSession,
    required this.onSignOut,
  });

  final AuthSession authSession;
  final Future<void> Function() onSignOut;

  @override
  State<GamelanHomeShell> createState() => _GamelanHomeShellState();
}

class _GamelanHomeShellState extends State<GamelanHomeShell> {
  int _selectedIndex = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
    NavigationDestination(icon: Icon(Icons.edit_note), label: 'Contribute'),
    NavigationDestination(
      icon: Icon(Icons.fact_check_outlined),
      label: 'Review',
    ),
    NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const EntityListScreen(),
      const ContributionListScreen(),
      widget.authSession.canAccessReviewWorkflow
          ? const ReviewQueueScreen()
          : const _ProtectedReviewTab(),
      _ProfileTab(authSession: widget.authSession, onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _ProtectedReviewTab extends StatelessWidget {
  const _ProtectedReviewTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ReviewAccessAppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 40),
              SizedBox(height: 16),
              Text(
                'Review access is protected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Your backend profile does not include a reviewer, curator, expert validator, or admin role. The mobile app hides this workflow for clarity, but backend policies remain the source of truth for every protected action.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewAccessAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ReviewAccessAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Review'));
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final store = GamelanScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final counts = store.contributionStatusCounts;
        final featuredItems = store.knowledgeItems
            .take(3)
            .toList(growable: false);

        return Scaffold(
          appBar: AppBar(title: const Text('Gamelan Knowledge MVP')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backend-connected MVP',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Contributions, media attachments, review, and published knowledge load from the Laravel API. RDF publication and offline sync are not implemented yet.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Featured knowledge',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final item in featuredItems)
                Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.knowledgeType} • ${item.gamelanType}',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Contribution status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in ContributionStatus.values)
                    StatusBadge(
                      status: status,
                      label: '${status.label}: ${counts[status] ?? 0}',
                      dense: true,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.authSession, required this.onSignOut});

  final AuthSession authSession;
  final Future<void> Function() onSignOut;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(widget.authSession.displayLabel),
            subtitle: const Text(
              'Signed in through the backend API. Role labels are not trusted for authorization on the device.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Backend roles'),
            subtitle: Text(widget.authSession.roleLabel),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy boundary'),
            subtitle: Text(
              'The access token is stored in secure device storage. Backend policies remain the source of truth for protected data and actions.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.account_tree_outlined),
            title: Text('Ontology boundary'),
            subtitle: Text(
              'Published knowledge comes from the backend API and is not direct RDF publication from this device.',
            ),
          ),
          if (widget.authSession.canAccessAdminTools) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin tools'),
              subtitle: const Text(
                'Read-only user management and audit logs from backend-admin endpoints.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminToolsScreen(),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(_isSigningOut ? 'Signing out...' : 'Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });
    await widget.onSignOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSigningOut = false;
    });
  }
}

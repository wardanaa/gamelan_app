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
import 'features/contributions/data/contribution_model.dart';
import 'features/contributions/screens/contribution_list_screen.dart';
import 'features/knowledge/screens/entity_list_screen.dart';
import 'features/review/screens/review_queue_screen.dart';

class GamelanApp extends StatefulWidget {
  const GamelanApp({super.key, AuthRepository? authRepository})
    : _authRepository = authRepository;

  final AuthRepository? _authRepository;

  @override
  State<GamelanApp> createState() => _GamelanAppState();
}

class _GamelanAppState extends State<GamelanApp> {
  late final GamelanMvpStore _store = GamelanMvpStore();
  late final AuthRepository _authRepository =
      widget._authRepository ??
      AuthRepository(
        apiClient: ApiClient.fromEnvironment(),
        tokenStorage: const TokenStorage(),
      );

  AuthSession? _authSession;
  bool _isRestoringSession = true;

  @override
  void initState() {
    super.initState();
    unawaited(_store.loadRepositoryState());
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

    setState(() {
      _authSession = switch (result) {
        Success<AuthSession>(:final value) => value,
        Failure<AuthSession>() => null,
      };
      _isRestoringSession = false;
    });
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
                'Your backend profile does not include a reviewer, curator, expert validator, or admin role. The mobile app hides this local workflow for clarity, but backend policies remain the source of truth for every protected action.',
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
    final counts = store.contributionStatusCounts;
    final featuredItems = store.knowledgeItems.take(3).toList(growable: false);

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
                    'Local prototype',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This demo persists non-sensitive drafts locally. It does not sync, publish RDF, call SPARQL, or store sensitive content after restart.',
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
                subtitle: Text('${item.knowledgeType} • ${item.gamelanType}'),
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
                Chip(label: Text('${status.label}: ${counts[status] ?? 0}')),
            ],
          ),
        ],
      ),
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
              'Approved local content is demo knowledge only and is not RDF publication.',
            ),
          ),
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

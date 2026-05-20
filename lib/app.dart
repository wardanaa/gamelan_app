import 'dart:async';

import 'package:flutter/material.dart';

import 'core/state/gamelan_mvp_store.dart';
import 'core/state/gamelan_scope.dart';
import 'features/contributions/data/contribution_model.dart';
import 'features/contributions/screens/contribution_list_screen.dart';
import 'features/knowledge/screens/entity_list_screen.dart';
import 'features/review/screens/review_queue_screen.dart';

class GamelanApp extends StatefulWidget {
  const GamelanApp({super.key});

  @override
  State<GamelanApp> createState() => _GamelanAppState();
}

class _GamelanAppState extends State<GamelanApp> {
  late final GamelanMvpStore _store = GamelanMvpStore();

  @override
  void initState() {
    super.initState();
    unawaited(_store.loadPersistedDrafts());
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
        home: const GamelanHomeShell(),
      ),
    );
  }
}

class GamelanHomeShell extends StatefulWidget {
  const GamelanHomeShell({super.key});

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
      const ReviewQueueScreen(),
      const _ProfileTab(),
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Demo contributor'),
            subtitle: Text('Local roles: Contributor and Curator'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy boundary'),
            subtitle: Text(
              'Tokens, backend authorization, media controls, and secure storage are not implemented in this local MVP.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_tree_outlined),
            title: Text('Ontology boundary'),
            subtitle: Text(
              'Approved local content is demo knowledge only and is not RDF publication.',
            ),
          ),
        ],
      ),
    );
  }
}

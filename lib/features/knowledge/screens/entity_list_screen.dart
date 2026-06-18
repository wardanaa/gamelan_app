import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../data/knowledge_item.dart';
import 'entity_detail_screen.dart';

class EntityListScreen extends StatefulWidget {
  const EntityListScreen({super.key});

  @override
  State<EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends State<EntityListScreen> {
  final _searchController = TextEditingController();
  String? _selectedGamelanType;
  String? _selectedKnowledgeType;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runSearch());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GamelanScope.of(context),
      builder: (context, _) {
        final store = GamelanScope.of(context);
        final results = _searchController.text.trim().isEmpty
            ? store.knowledgeItems
            : store.searchResults;

        return Scaffold(
          appBar: const _KnowledgeAppBar(title: 'Search knowledge'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Keyword',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => unawaited(_runSearch()),
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterMenu(
                    label: 'Gamelan type',
                    value: _selectedGamelanType,
                    options: store.gamelanTypeLabels,
                    onChanged: (value) {
                      setState(() {
                        _selectedGamelanType = value;
                      });
                      unawaited(_runSearch());
                    },
                  ),
                  _FilterMenu(
                    label: 'Knowledge type',
                    value: _selectedKnowledgeType,
                    options: store.knowledgeTypeLabels,
                    onChanged: (value) {
                      setState(() {
                        _selectedKnowledgeType = value;
                      });
                      unawaited(_runSearch());
                    },
                  ),
                  if (_selectedGamelanType != null ||
                      _selectedKnowledgeType != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedGamelanType = null;
                          _selectedKnowledgeType = null;
                        });
                        unawaited(_runSearch());
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear filters'),
                    ),
                ],
              ),
              if (store.isSearching) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (store.lastError != null) ...[
                const SizedBox(height: 16),
                Text(
                  store.lastError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (store.searchNotice != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: _SearchNotice(message: store.searchNotice!),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                '${results.length} knowledge items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (results.isEmpty && !store.isSearching)
                const Text(
                  'No published knowledge matched this search. Unpublished or restricted content is not shown.',
                ),
              for (final item in results) _KnowledgeItemCard(item: item),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runSearch() async {
    final store = GamelanScope.of(context);
    await store.searchKnowledge(
      query: _searchController.text,
      gamelanType: _selectedGamelanType,
      knowledgeType: _selectedKnowledgeType,
    );
  }
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.onSecondaryContainer,
              semanticLabel: 'Search notice',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String?>(
      label: Text(label),
      initialSelection: value,
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: null, label: 'All'),
        for (final option in options)
          DropdownMenuEntry(value: option, label: option),
      ],
      onSelected: onChanged,
    );
  }
}

class _KnowledgeItemCard extends StatelessWidget {
  const _KnowledgeItemCard({required this.item});

  final KnowledgeItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.title),
        subtitle: Text('${item.knowledgeType} • ${item.gamelanType}'),
        trailing: item.isCommunityApproved
            ? const Icon(
                Icons.verified_outlined,
                semanticLabel: 'Published knowledge',
              )
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => EntityDetailScreen(itemId: item.id),
            ),
          );
        },
      ),
    );
  }
}

class _KnowledgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _KnowledgeAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

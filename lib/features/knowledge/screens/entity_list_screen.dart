import 'package:flutter/material.dart';

import '../../../core/state/gamelan_mvp_store.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = GamelanScope.of(context);
    final results = store.searchKnowledge(
      query: _searchController.text,
      gamelanType: _selectedGamelanType,
      knowledgeType: _selectedKnowledgeType,
    );

    return Scaffold(
      appBar: const _KnowledgeAppBar(title: 'Search knowledge'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Keyword or relation',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterMenu(
                label: 'Gamelan type',
                value: _selectedGamelanType,
                options: GamelanMvpStore.gamelanTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedGamelanType = value;
                  });
                },
              ),
              _FilterMenu(
                label: 'Knowledge type',
                value: _selectedKnowledgeType,
                options: GamelanMvpStore.knowledgeTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedKnowledgeType = value;
                  });
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
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear filters'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${results.length} knowledge items',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final item in results) _KnowledgeItemCard(item: item),
        ],
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
                semanticLabel: 'Community approved demo content',
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

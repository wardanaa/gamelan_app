import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../widgets/contribution_card.dart';
import 'contribution_detail_screen.dart';
import 'contribution_form_screen.dart';

class ContributionListScreen extends StatelessWidget {
  const ContributionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GamelanScope.of(context);
    final contributions = store.contributions;

    return Scaffold(
      appBar: const _ContributionAppBar(title: 'Contributions'),
      body: contributions.isEmpty
          ? const Center(child: Text('No local contributions yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: contributions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: Text(
                      'Local prototype: non-sensitive drafts are stored on this device. Sensitive drafts and submitted items are session-only.',
                    ),
                  );
                }
                final contribution = contributions[index - 1];
                return ContributionCard(
                  contribution: contribution,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ContributionDetailScreen(
                          contributionId: contribution.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const ContributionFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New contribution'),
      ),
    );
  }
}

class _ContributionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContributionAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

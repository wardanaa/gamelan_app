import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../data/contribution_model.dart';
import '../widgets/status_badge.dart';

class ContributionStatusScreen extends StatelessWidget {
  const ContributionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counts = GamelanScope.of(context).contributionStatusCounts;

    return Scaffold(
      appBar: const _ContributionStatusAppBar(title: 'Contribution status'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final status in ContributionStatus.values)
            ListTile(
              leading: StatusBadge(status: status, dense: true),
              title: Text(status.label),
              trailing: Text('${counts[status] ?? 0}'),
            ),
        ],
      ),
    );
  }
}

class _ContributionStatusAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContributionStatusAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

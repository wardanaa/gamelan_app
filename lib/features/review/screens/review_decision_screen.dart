import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';

enum ReviewDecisionAction { approve, requestChanges, reject }

class ReviewDecisionScreen extends StatefulWidget {
  const ReviewDecisionScreen({
    required this.action,
    required this.contributionId,
    super.key,
  });

  final ReviewDecisionAction action;
  final String contributionId;

  @override
  State<ReviewDecisionScreen> createState() => _ReviewDecisionScreenState();
}

class _ReviewDecisionScreenState extends State<ReviewDecisionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ReviewDecisionAppBar(title: widget.action.label),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.action.explanation,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Review note',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'A review note is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitDecision,
              icon: Icon(widget.action.icon),
              label: Text(widget.action.label),
            ),
          ],
        ),
      ),
    );
  }

  void _submitDecision() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = GamelanScope.of(context);
    final note = _noteController.text.trim();
    switch (widget.action) {
      case ReviewDecisionAction.approve:
        store.approveContribution(widget.contributionId, note);
      case ReviewDecisionAction.requestChanges:
        store.requestChanges(widget.contributionId, note);
      case ReviewDecisionAction.reject:
        store.rejectContribution(widget.contributionId, note);
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

extension on ReviewDecisionAction {
  String get label {
    return switch (this) {
      ReviewDecisionAction.approve => 'Approve',
      ReviewDecisionAction.requestChanges => 'Request changes',
      ReviewDecisionAction.reject => 'Reject',
    };
  }

  String get explanation {
    return switch (this) {
      ReviewDecisionAction.approve =>
        'Approved contributions become searchable community approved demo content.',
      ReviewDecisionAction.requestChanges =>
        'Change requests keep the contribution out of public knowledge browsing.',
      ReviewDecisionAction.reject =>
        'Rejected contributions remain private to this local workflow.',
    };
  }

  IconData get icon {
    return switch (this) {
      ReviewDecisionAction.approve => Icons.check_circle_outline,
      ReviewDecisionAction.requestChanges => Icons.edit_outlined,
      ReviewDecisionAction.reject => Icons.cancel_outlined,
    };
  }
}

class _ReviewDecisionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ReviewDecisionAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

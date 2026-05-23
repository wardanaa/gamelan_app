import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../widgets/review_note_field.dart';

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
            ReviewNoteField(
              noteController: _noteController,
              noteFieldKey: const Key('review_decision_note_field'),
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

  Future<void> _submitDecision() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = GamelanScope.of(context);
    final note = _noteController.text.trim();
    final Result<void> result = switch (widget.action) {
      ReviewDecisionAction.approve => await store.approveContribution(
        widget.contributionId,
        note,
      ),
      ReviewDecisionAction.requestChanges => await store.requestChanges(
        widget.contributionId,
        note,
      ),
      ReviewDecisionAction.reject => await store.rejectContribution(
        widget.contributionId,
        note,
      ),
    };

    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<void>():
        Navigator.of(context).popUntil((route) => route.isFirst);
      case Failure<void>(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
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
        'Approval is recorded through the backend review API. Publication still requires backend workflow and ontology mapping.',
      ReviewDecisionAction.requestChanges =>
        'The contributor can revise and resubmit when the backend allows it.',
      ReviewDecisionAction.reject =>
        'Rejected contributions remain unavailable in public knowledge browsing.',
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

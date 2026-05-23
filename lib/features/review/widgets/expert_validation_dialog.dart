import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import 'review_note_field.dart';

class ExpertValidationDialog extends StatefulWidget {
  const ExpertValidationDialog({required this.contributionId, super.key});

  final String contributionId;

  @override
  State<ExpertValidationDialog> createState() => _ExpertValidationDialogState();
}

class _ExpertValidationDialogState extends State<ExpertValidationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _privateNoteController = TextEditingController();

  String? _decision = 'approve';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    _privateNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Expert validation'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Record the expert decision and keep the public note separate from the private reviewer note.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('expert_decision_field'),
                initialValue: _decision,
                decoration: const InputDecoration(
                  labelText: 'Decision',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'approve', child: Text('Approve')),
                  DropdownMenuItem(value: 'reject', child: Text('Reject')),
                  DropdownMenuItem(
                    value: 'request_revision',
                    child: Text('Request revision'),
                  ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() {
                        _decision = value;
                      }),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Select an expert decision.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ReviewNoteField(
                noteController: _noteController,
                noteLabel: 'Public note',
                noteHintText: 'Visible to the contributor.',
                noteRequiredMessage: 'A public note is required.',
                noteFieldKey: const Key('expert_public_note_field'),
                allowPrivateNote: true,
                privateNoteController: _privateNoteController,
                privateNoteLabel: 'Private note',
                privateNoteHintText: 'For reviewers and experts only.',
                privateNoteFieldKey: const Key('expert_private_note_field'),
                privateToggleKey: const Key('expert_private_note_toggle'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_outlined),
          label: const Text('Validate'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final decision = _decision;
    if (decision == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await GamelanScope.of(context).expertValidate(
      widget.contributionId,
      decision,
      _noteController.text.trim(),
      _privateNoteController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<void>():
        Navigator.of(context).pop();
        return;
      case Failure<void>(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

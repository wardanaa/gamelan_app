import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import 'review_note_field.dart';

class MarkExpertRequiredDialog extends StatefulWidget {
  const MarkExpertRequiredDialog({required this.contributionId, super.key});

  final String contributionId;

  @override
  State<MarkExpertRequiredDialog> createState() =>
      _MarkExpertRequiredDialogState();
}

class _MarkExpertRequiredDialogState extends State<MarkExpertRequiredDialog> {
  static const _reasons = <_ExpertReasonOption>[
    _ExpertReasonOption('origin_claim', 'Origin claim'),
    _ExpertReasonOption('curator_flagged', 'Curator flagged'),
    _ExpertReasonOption('sacred_knowledge', 'Sacred or restricted knowledge'),
    _ExpertReasonOption('ritual_specific', 'Ritual-specific content'),
    _ExpertReasonOption('historical_claim', 'Historical claim'),
    _ExpertReasonOption('disputed_terminology', 'Disputed terminology'),
    _ExpertReasonOption(
      'sensitive_community_practice',
      'Sensitive community practice',
    ),
    _ExpertReasonOption('high_impact_correction', 'High-impact correction'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final Set<String> _selectedReasons = <String>{};

  bool _isSubmitting = false;
  String? _reasonError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request expert validation'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Mark this contribution for expert review and select the reason(s) that triggered the escalation.',
              ),
              const SizedBox(height: 16),
              ReviewNoteField(
                noteController: _noteController,
                noteLabel: 'Public note',
                noteHintText: 'Explain why expert validation is needed.',
                noteRequiredMessage: 'A public note is required.',
                noteFieldKey: const Key('mark_expert_public_note_field'),
              ),
              const SizedBox(height: 16),
              Text(
                'Expert required reasons',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              if (_reasonError != null)
                Text(
                  _reasonError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 8),
              for (final reason in _reasons)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(reason.label),
                  value: _selectedReasons.contains(reason.value),
                  onChanged: _isSubmitting
                      ? null
                      : (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedReasons.add(reason.value);
                            } else {
                              _selectedReasons.remove(reason.value);
                            }
                            _reasonError = null;
                          });
                        },
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
              : const Icon(Icons.shield_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedReasons.isEmpty) {
      setState(() {
        _reasonError = 'Select at least one reason.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _reasonError = null;
    });

    final result = await GamelanScope.of(context).markExpertRequired(
      widget.contributionId,
      _noteController.text.trim(),
      _reasons
          .where((reason) => _selectedReasons.contains(reason.value))
          .map((reason) => reason.value)
          .toList(growable: false),
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

class _ExpertReasonOption {
  const _ExpertReasonOption(this.value, this.label);

  final String value;
  final String label;
}

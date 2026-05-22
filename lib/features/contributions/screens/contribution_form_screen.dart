import 'package:flutter/material.dart';

import '../../../core/api/repository_errors.dart';
import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../../contributions/data/contribution_model.dart';

class ContributionFormScreen extends StatefulWidget {
  const ContributionFormScreen({super.key});

  @override
  State<ContributionFormScreen> createState() => _ContributionFormScreenState();
}

class _ContributionFormScreenState extends State<ContributionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceNoteController = TextEditingController();
  final _contributorNoteController = TextEditingController();

  String? _knowledgeType;
  String? _gamelanType;
  String? _contributionIntent = TaxonomyMapper.contributionIntents.first.slug;
  bool _culturalSensitivity = false;
  bool _consentGiven = false;
  bool _isSaving = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = GamelanScope.of(context);
    _knowledgeType ??= store.knowledgeTypeLabels.firstOrNull;
    _gamelanType ??= store.gamelanTypeLabels.firstOrNull;
    _contributionIntent ??= store.contributionIntentOptions.first.slug;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sourceNoteController.dispose();
    _contributorNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = GamelanScope.of(context);

    return Scaffold(
      appBar: const _ContributionFormAppBar(title: 'New contribution'),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const Key('contribution_form_scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Submit community knowledge for curator review. The backend validates every submission before review or publication.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: const OutlineInputBorder(),
                errorText: _fieldError('title'),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: const OutlineInputBorder(),
                errorText: _fieldError('description'),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _knowledgeType,
              decoration: const InputDecoration(
                labelText: 'Knowledge type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final type in store.knowledgeTypeLabels)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) {
                setState(() {
                  _knowledgeType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gamelanType,
              decoration: const InputDecoration(
                labelText: 'Gamelan type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final type in store.gamelanTypeLabels)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) {
                setState(() {
                  _gamelanType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _contributionIntent,
              decoration: InputDecoration(
                labelText: 'Contribution intent',
                border: const OutlineInputBorder(),
                errorText: _fieldError('contribution_intent'),
              ),
              items: [
                for (final intent in store.contributionIntentOptions)
                  DropdownMenuItem(
                    value: intent.slug,
                    child: Text(intent.label),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _contributionIntent = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceNoteController,
              decoration: InputDecoration(
                labelText: 'Source note',
                border: const OutlineInputBorder(),
                errorText: _fieldError('source_note'),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contributorNoteController,
              decoration: InputDecoration(
                labelText: 'Contributor note',
                border: const OutlineInputBorder(),
                errorText: _fieldError('contributor_note'),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Culturally sensitive'),
              subtitle: const Text(
                'Use this for ritual, restricted, disputed, or community-specific knowledge.',
              ),
              value: _culturalSensitivity,
              onChanged: (value) {
                setState(() {
                  _culturalSensitivity = value;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Contributor consent confirmed'),
              subtitle: const Text(
                'Required before saving or submitting this contribution.',
              ),
              value: _consentGiven,
              onChanged: (value) {
                setState(() {
                  _consentGiven = value ?? false;
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => _saveContribution(submitForReview: true),
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Submit for review'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => _saveContribution(submitForReview: false),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save draft'),
            ),
          ],
        ),
      ),
    );
  }

  String? _fieldError(String key) {
    final messages = _fieldErrors[key];
    if (messages == null || messages.isEmpty) {
      return null;
    }
    return messages.first;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _requiredForSubmitValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required before submission.';
    }
    return null;
  }

  Future<void> _saveContribution({required bool submitForReview}) async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contributor consent is required before saving.'),
        ),
      );
      return;
    }

    setState(() {
      _fieldErrors = const {};
    });

    final titleError = _requiredValidator(_titleController.text);
    final descriptionError = submitForReview
        ? _requiredForSubmitValidator(_descriptionController.text)
        : null;
    final sourceNoteError = submitForReview
        ? _requiredForSubmitValidator(_sourceNoteController.text)
        : null;
    final intentError = submitForReview && (_contributionIntent == null)
        ? 'Contribution intent is required before submission.'
        : null;

    if (titleError != null ||
        descriptionError != null ||
        sourceNoteError != null ||
        intentError != null) {
      _formKey.currentState?.validate();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submitForReview
                ? 'Complete the required fields before submitting for review.'
                : 'A title is required to save a draft.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final store = GamelanScope.of(context);
    final result = await store.createContribution(
      title: _titleController.text,
      description: _descriptionController.text,
      knowledgeType: _knowledgeType ?? store.knowledgeTypeLabels.first,
      gamelanType: _gamelanType ?? store.gamelanTypeLabels.first,
      sourceNote: _sourceNoteController.text,
      contributorNote: _contributorNoteController.text,
      culturalSensitivity: _culturalSensitivity,
      consentGiven: _consentGiven,
      submitForReview: submitForReview,
      contributionIntent: _contributionIntent,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    switch (result) {
      case Success<ContributionModel>():
        Navigator.of(context).pop();
      case Failure<ContributionModel>(:final message, :final exception):
        final validation = validationExceptionFrom(exception);
        setState(() {
          _fieldErrors = validation?.fieldErrors ?? const {};
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validation?.message ?? message)));
    }
  }
}

class _ContributionFormAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContributionFormAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

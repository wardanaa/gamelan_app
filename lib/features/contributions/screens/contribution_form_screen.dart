import 'package:flutter/material.dart';

import '../../../core/api/repository_errors.dart';
import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/state/gamelan_mvp_store.dart';
import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../../contributions/data/contribution_model.dart';

class ContributionFormScreen extends StatefulWidget {
  const ContributionFormScreen({this.contribution, super.key});

  final ContributionModel? contribution;

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

  bool get _isEditing => widget.contribution != null;

  @override
  void initState() {
    super.initState();
    final contribution = widget.contribution;
    if (contribution == null) {
      return;
    }

    _titleController.text = contribution.title;
    _descriptionController.text = contribution.description;
    _sourceNoteController.text = contribution.sourceNote;
    _contributorNoteController.text = contribution.contributorNote;
    _knowledgeType = contribution.knowledgeType;
    _gamelanType = contribution.gamelanType;
    _contributionIntent =
        contribution.contributionIntent ??
        TaxonomyMapper.contributionIntents.first.slug;
    _culturalSensitivity = contribution.culturalSensitivity;
    _consentGiven = contribution.consentGiven;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = GamelanScope.of(context);
    _knowledgeType = _optionOrFallback(
      store.knowledgeTypeLabels,
      _knowledgeType,
    );
    _gamelanType = _optionOrFallback(store.gamelanTypeLabels, _gamelanType);
    _contributionIntent = _intentOrFallback(
      store.contributionIntentOptions,
      _contributionIntent,
    );
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
    final canSubmit = !_isEditing || (widget.contribution?.canSubmit ?? false);

    return Scaffold(
      appBar: _ContributionFormAppBar(
        title: _isEditing ? 'Edit contribution' : 'New contribution',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const Key('contribution_form_scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _isEditing
                  ? 'Revise this contribution for curator review. The backend validates every update and controls whether resubmission is allowed.'
                  : 'Submit community knowledge for curator review. The backend validates every submission before review or publication.',
            ),
            if (_shouldShowRevisionGuidance) ...[
              const SizedBox(height: 12),
              _RevisionGuidanceCard(contribution: widget.contribution!),
            ],
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
            if (canSubmit) ...[
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
                label: Text(
                  _isEditing
                      ? 'Save and submit for review'
                      : 'Submit for review',
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => _saveContribution(submitForReview: false),
              icon: const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Save changes' : 'Save draft'),
            ),
          ],
        ),
      ),
    );
  }

  String? _optionOrFallback(List<String> options, String? selected) {
    if (selected != null && options.contains(selected)) {
      return selected;
    }
    return options.firstOrNull;
  }

  bool get _shouldShowRevisionGuidance {
    final contribution = widget.contribution;
    if (contribution == null ||
        contribution.status != ContributionStatus.needsRevision ||
        (!contribution.canEdit && !contribution.canSubmit)) {
      return false;
    }
    return contribution.statusDescription?.trim().isNotEmpty == true ||
        contribution.reviewNote?.trim().isNotEmpty == true;
  }

  String? _intentOrFallback(List<TaxonomyOption> options, String? selected) {
    if (selected != null && options.any((option) => option.slug == selected)) {
      return selected;
    }
    return options.firstOrNull?.slug;
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
    final result = await _saveToRepository(
      store,
      submitForReview: submitForReview,
    );

    if (submitForReview) {
      switch (result) {
        case Success<ContributionModel>(:final value):
          final submitResult = await store.submitContribution(value.id);
          if (!mounted) {
            return;
          }
          switch (submitResult) {
            case Success<ContributionModel>():
              setState(() {
                _isSaving = false;
              });
              Navigator.of(context).pop();
            case Failure<ContributionModel>(:final message, :final exception):
              _showFailure(message, exception);
          }
        case Failure<ContributionModel>(:final message, :final exception):
          if (!mounted) {
            return;
          }
          _showFailure(message, exception);
      }
      return;
    }

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
        _showFailure(message, exception);
    }
  }

  Future<Result<ContributionModel>> _saveToRepository(
    GamelanMvpStore store, {
    required bool submitForReview,
  }) {
    final contribution = widget.contribution;
    if (contribution == null) {
      return store.createContribution(
        title: _titleController.text,
        description: _descriptionController.text,
        knowledgeType: _knowledgeType ?? store.knowledgeTypeLabels.first,
        gamelanType: _gamelanType ?? store.gamelanTypeLabels.first,
        sourceNote: _sourceNoteController.text,
        contributorNote: _contributorNoteController.text,
        culturalSensitivity: _culturalSensitivity,
        consentGiven: _consentGiven,
        submitForReview: false,
        contributionIntent: _contributionIntent,
      );
    }

    return store.updateContribution(
      id: contribution.id,
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
      lastKnownUpdatedAt: contribution.updatedAt,
    );
  }

  void _showFailure(String message, Object? exception) {
    final validation = validationExceptionFrom(exception);
    setState(() {
      _isSaving = false;
      _fieldErrors = validation?.fieldErrors ?? const {};
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(validation?.message ?? message)));
  }
}

class _RevisionGuidanceCard extends StatelessWidget {
  const _RevisionGuidanceCard({required this.contribution});

  final ContributionModel contribution;

  @override
  Widget build(BuildContext context) {
    final statusDescription = contribution.statusDescription?.trim();
    final reviewNote = contribution.reviewNote?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review guidance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (statusDescription != null && statusDescription.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(statusDescription),
            ],
            if (reviewNote != null && reviewNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reviewNote),
            ],
          ],
        ),
      ),
    );
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

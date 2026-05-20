import 'package:flutter/material.dart';

import '../../../core/state/gamelan_mvp_store.dart';
import '../../../core/state/gamelan_scope.dart';

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

  String _knowledgeType = GamelanMvpStore.knowledgeTypes.first;
  String _gamelanType = GamelanMvpStore.gamelanTypes.first;
  bool _culturalSensitivity = false;
  bool _consentGiven = false;

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
    return Scaffold(
      appBar: const _ContributionFormAppBar(title: 'New contribution'),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const Key('contribution_form_scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Submit community knowledge for curator review. Sensitive or unverified content is never published directly.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _knowledgeType,
              decoration: const InputDecoration(
                labelText: 'Knowledge type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final type in GamelanMvpStore.knowledgeTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) {
                setState(() {
                  _knowledgeType = value ?? _knowledgeType;
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
                for (final type in GamelanMvpStore.gamelanTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) {
                setState(() {
                  _gamelanType = value ?? _gamelanType;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceNoteController,
              decoration: const InputDecoration(
                labelText: 'Source note',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contributorNoteController,
              decoration: const InputDecoration(
                labelText: 'Contributor note',
                border: OutlineInputBorder(),
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
                'Required before saving or submitting this local contribution.',
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
              onPressed: () => _saveContribution(submitForReview: true),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit for review'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _saveContribution(submitForReview: false),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save draft'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  Future<void> _saveContribution({required bool submitForReview}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contributor consent is required before saving.'),
        ),
      );
      return;
    }

    final store = GamelanScope.of(context);
    await store.createContribution(
      title: _titleController.text,
      description: _descriptionController.text,
      knowledgeType: _knowledgeType,
      gamelanType: _gamelanType,
      sourceNote: _sourceNoteController.text,
      contributorNote: _contributorNoteController.text,
      culturalSensitivity: _culturalSensitivity,
      consentGiven: _consentGiven,
      submitForReview: submitForReview,
    );
    if (!mounted) {
      return;
    }
    if (!submitForReview && _culturalSensitivity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sensitive drafts stay in this session only until encrypted storage rules are added.',
          ),
        ),
      );
    }
    Navigator.of(context).pop();
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

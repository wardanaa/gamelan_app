import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../data/media_asset_model.dart';

class MediaUploadScreen extends StatefulWidget {
  const MediaUploadScreen({required this.contributionId, super.key});

  final String contributionId;

  @override
  State<MediaUploadScreen> createState() => _MediaUploadScreenState();
}

class _MediaUploadScreenState extends State<MediaUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creatorController = TextEditingController();
  final _creditController = TextEditingController();
  final _licenseController = TextEditingController();
  final _recordingDateController = TextEditingController();
  final _recordingPlaceController = TextEditingController();
  final _relatedEntityController = TextEditingController();
  final _altTextController = TextEditingController();

  MediaType _mediaType = MediaType.image;
  MediaConsentStatus _consentStatus = MediaConsentStatus.unknown;
  MediaVisibility _visibility = MediaVisibility.private;
  bool _culturalSensitivity = false;
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _creatorController.dispose();
    _creditController.dispose();
    _licenseController.dispose();
    _recordingDateController.dispose();
    _recordingPlaceController.dispose();
    _relatedEntityController.dispose();
    _altTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add media')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Attach media as evidence for curator review. The app uploads safe metadata and file content to the Laravel API; public exposure is controlled by backend validation.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MediaType>(
              initialValue: _mediaType,
              decoration: const InputDecoration(labelText: 'Media type'),
              items: [
                for (final type in MediaType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _mediaType = value;
                        _selectedFile = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _selectedFile == null ? 'Choose file' : _selectedFile!.name,
              ),
            ),
            if (_fieldErrors['file'] != null)
              _FieldErrorText(messages: _fieldErrors['file']!),
            if (_selectedFile != null) ...[
              const SizedBox(height: 4),
              Text(_fileSummary(_selectedFile!)),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _firstFieldError('title'),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a media title.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                errorText: _firstFieldError('description'),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MediaConsentStatus>(
              initialValue: _consentStatus,
              decoration: InputDecoration(
                labelText: 'Consent status',
                errorText: _firstFieldError('consent_status'),
              ),
              items: [
                for (final status in MediaConsentStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() {
                      _consentStatus = value ?? MediaConsentStatus.unknown;
                    }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MediaVisibility>(
              initialValue: _visibility,
              decoration: InputDecoration(
                labelText: 'Visibility',
                errorText: _firstFieldError('visibility'),
              ),
              items: [
                for (final visibility in MediaVisibility.values)
                  DropdownMenuItem(
                    value: visibility,
                    child: Text(visibility.label),
                  ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() {
                      _visibility = value ?? MediaVisibility.private;
                    }),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Culturally sensitive media'),
              value: _culturalSensitivity,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() {
                      _culturalSensitivity = value;
                    }),
            ),
            _OptionalField(
              controller: _creatorController,
              label: 'Creator',
              errorText: _firstFieldError('creator'),
            ),
            _OptionalField(
              controller: _creditController,
              label: 'Credit',
              errorText: _firstFieldError('credit'),
            ),
            _OptionalField(
              controller: _licenseController,
              label: 'License',
              errorText: _firstFieldError('license'),
            ),
            _OptionalField(
              controller: _recordingDateController,
              label: 'Recording date',
              hintText: 'YYYY-MM-DD',
              errorText: _firstFieldError('recording_date'),
            ),
            _OptionalField(
              controller: _recordingPlaceController,
              label: 'Recording place',
              errorText: _firstFieldError('recording_place'),
            ),
            _OptionalField(
              controller: _relatedEntityController,
              label: 'Related entity label',
              errorText: _firstFieldError('related_entity_label'),
            ),
            _OptionalField(
              controller: _altTextController,
              label: 'Alternative text',
              errorText: _firstFieldError('alt_text'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload media'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensionsFor(_mediaType),
      withData: false,
    );
    final file = result?.files.single;
    if (file == null) {
      return;
    }
    setState(() {
      _selectedFile = file;
      _fieldErrors = const {};
    });
  }

  Future<void> _submit() async {
    final clientErrors = _clientErrors();
    setState(() {
      _fieldErrors = clientErrors;
    });
    if (!_formKey.currentState!.validate() || clientErrors.isNotEmpty) {
      return;
    }

    final file = _selectedFile!;
    setState(() {
      _isSubmitting = true;
    });

    final store = GamelanScope.of(context);
    final result = await store.uploadContributionMedia(
      widget.contributionId,
      MediaUploadInput(
        title: _titleController.text,
        description: _descriptionController.text,
        mediaType: _mediaType,
        consentStatus: _consentStatus,
        visibility: _visibility,
        culturalSensitivity: _culturalSensitivity,
        filename: file.name,
        filePath: file.path,
        bytes: file.bytes,
        creator: _creatorController.text,
        credit: _creditController.text,
        license: _licenseController.text,
        recordingDate: _recordingDateController.text,
        recordingPlace: _recordingPlaceController.text,
        relatedEntityLabel: _relatedEntityController.text,
        altText: _altTextController.text,
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });

    switch (result) {
      case Success<MediaAssetModel>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media uploaded for curator review.')),
        );
        Navigator.of(context).pop();
      case Failure<MediaAssetModel>(:final message):
        setState(() {
          _fieldErrors =
              store.mediaValidationErrorsFromFailure(result) ?? const {};
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Map<String, List<String>> _clientErrors() {
    final errors = <String, List<String>>{};
    final file = _selectedFile;
    if (file == null) {
      errors['file'] = ['Choose a file to upload.'];
    } else if ((file.path == null || file.path!.isEmpty) &&
        file.bytes == null) {
      errors['file'] = ['The selected file could not be read for upload.'];
    } else if (file.size > _maxBytesFor(_mediaType)) {
      errors['file'] = [
        'The selected ${_mediaType.label.toLowerCase()} exceeds the ${_maxMegabytesFor(_mediaType)} MB limit.',
      ];
    }

    if (_consentStatus == MediaConsentStatus.revoked) {
      errors['consent_status'] = ['Revoked consent cannot be uploaded.'];
    }
    if (_visibility == MediaVisibility.public &&
        !_consentStatus.permitsPublic) {
      errors['visibility'] = [
        'Public media requires granted consent or no required consent.',
      ];
    }
    if (_visibility == MediaVisibility.public && _culturalSensitivity) {
      errors['visibility'] = [
        'Culturally sensitive media cannot be marked public.',
      ];
    }
    return errors;
  }

  String? _firstFieldError(String key) {
    final errors = _fieldErrors[key];
    if (errors == null || errors.isEmpty) {
      return null;
    }
    return errors.first;
  }

  String _fileSummary(PlatformFile file) {
    final sizeMb = file.size / (1024 * 1024);
    return '${file.extension ?? _mediaType.label} file, ${sizeMb.toStringAsFixed(2)} MB';
  }

  List<String> _extensionsFor(MediaType type) {
    return switch (type) {
      MediaType.image => const ['jpg', 'jpeg', 'png', 'webp'],
      MediaType.audio => const ['mp3', 'wav', 'ogg', 'm4a'],
      MediaType.video => const ['mp4', 'mov', 'webm'],
      MediaType.document => const ['pdf', 'txt', 'doc', 'docx'],
    };
  }

  int _maxMegabytesFor(MediaType type) {
    return switch (type) {
      MediaType.image => 10,
      MediaType.audio => 50,
      MediaType.video => 200,
      MediaType.document => 20,
    };
  }

  int _maxBytesFor(MediaType type) => _maxMegabytesFor(type) * 1024 * 1024;
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.controller,
    required this.label,
    this.hintText,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          errorText: errorText,
        ),
      ),
    );
  }
}

class _FieldErrorText extends StatelessWidget {
  const _FieldErrorText({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        messages.join('\n'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

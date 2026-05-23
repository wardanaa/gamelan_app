import 'package:flutter/material.dart';

class ReviewNoteField extends StatefulWidget {
  const ReviewNoteField({
    required this.noteController,
    this.noteLabel = 'Review note',
    this.noteHintText,
    this.noteRequiredMessage = 'A review note is required.',
    this.noteFieldKey,
    this.privateNoteController,
    this.allowPrivateNote = false,
    this.privateNoteLabel = 'Private note',
    this.privateNoteHintText,
    this.privateNoteHelpText,
    this.privateNoteFieldKey,
    this.privateToggleKey,
    super.key,
  });

  final TextEditingController noteController;
  final String noteLabel;
  final String? noteHintText;
  final String noteRequiredMessage;
  final Key? noteFieldKey;
  final TextEditingController? privateNoteController;
  final bool allowPrivateNote;
  final String privateNoteLabel;
  final String? privateNoteHintText;
  final String? privateNoteHelpText;
  final Key? privateNoteFieldKey;
  final Key? privateToggleKey;

  @override
  State<ReviewNoteField> createState() => _ReviewNoteFieldState();
}

class _ReviewNoteFieldState extends State<ReviewNoteField> {
  bool _privateNoteVisible = false;

  @override
  void didUpdateWidget(covariant ReviewNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.allowPrivateNote) {
      _privateNoteVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: widget.noteFieldKey,
          controller: widget.noteController,
          decoration: InputDecoration(
            labelText: widget.noteLabel,
            hintText: widget.noteHintText,
            border: const OutlineInputBorder(),
          ),
          minLines: 3,
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return widget.noteRequiredMessage;
            }
            return null;
          },
        ),
        if (widget.allowPrivateNote) ...[
          const SizedBox(height: 12),
          SwitchListTile(
            key: widget.privateToggleKey,
            contentPadding: EdgeInsets.zero,
            title: const Text('Add private note'),
            subtitle: Text(
              widget.privateNoteHelpText ??
                  'Visible only to reviewers and experts, not contributors.',
            ),
            value: _privateNoteVisible,
            onChanged: (value) {
              setState(() {
                _privateNoteVisible = value;
                if (!value) {
                  widget.privateNoteController?.clear();
                }
              });
            },
          ),
          if (_privateNoteVisible) ...[
            const SizedBox(height: 8),
            TextFormField(
              key: widget.privateNoteFieldKey,
              controller: widget.privateNoteController,
              decoration: InputDecoration(
                labelText: widget.privateNoteLabel,
                hintText: widget.privateNoteHintText,
                border: const OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ],
      ],
    );
  }
}

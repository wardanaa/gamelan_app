import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../../contributions/data/contribution_model.dart';
import '../../contributions/data/rdf_publication_model.dart';
import '../../ontology/data/ontology_class.dart';
import '../../ontology/data/ontology_mapping.dart';
import '../../ontology/data/ontology_property.dart';
import '../../ontology/data/ontology_relation.dart';

class RdfPublicationScreen extends StatefulWidget {
  const RdfPublicationScreen({required this.contribution, super.key});

  final ContributionModel contribution;

  @override
  State<RdfPublicationScreen> createState() => _RdfPublicationScreenState();
}

class _RdfPublicationScreenState extends State<RdfPublicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectSlugController = TextEditingController();
  final _preferredLabelController = TextEditingController();
  final _languageController = TextEditingController(text: 'id');
  final List<_RelationDraft> _relations = [];

  Future<_PublicationOptions>? _optionsFuture;
  String? _selectedOntologyClass;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _subjectSlugController.text = _slugFrom(widget.contribution.title);
    _preferredLabelController.text = widget.contribution.title;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _optionsFuture ??= _loadOptions();
  }

  @override
  void dispose() {
    _subjectSlugController.dispose();
    _preferredLabelController.dispose();
    _languageController.dispose();
    for (final relation in _relations) {
      relation.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RDF publication')),
      body: FutureBuilder<_PublicationOptions>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              message: snapshot.error.toString(),
              onRetry: _retryLoadOptions,
            );
          }

          final options = snapshot.data;
          if (options == null) {
            return _LoadError(
              message: 'Unable to load ontology publication options.',
              onRetry: _retryLoadOptions,
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.contribution.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Queue validated, non-sensitive knowledge for backend RDF publication. Backend authorization and ontology validation remain authoritative.',
                ),
                const SizedBox(height: 16),
                _SourceSummaryPreview(contribution: widget.contribution),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('rdf_ontology_class_field'),
                  initialValue: _selectedOntologyClass,
                  decoration: const InputDecoration(
                    labelText: 'Ontology class',
                    border: OutlineInputBorder(),
                  ),
                  items: options.classes
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.label,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOntologyClass = value;
                    });
                  },
                  validator: (value) => _required(value, 'Select a class.'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('rdf_subject_slug_field'),
                  controller: _subjectSlugController,
                  decoration: const InputDecoration(
                    labelText: 'Subject slug',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateSlug,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('rdf_preferred_label_field'),
                  controller: _preferredLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred label',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      _required(value, 'Enter a preferred label.'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('rdf_language_field'),
                  controller: _languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      _required(value, 'Enter a language code.'),
                ),
                const SizedBox(height: 20),
                _RelationEditor(
                  relations: _relations,
                  classes: options.classes,
                  properties: options.properties,
                  onAdd: _addRelation,
                  onRemove: _removeRelation,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('rdf_queue_publication_button'),
                  onPressed: _isSubmitting ? null : () => _queuePublication(),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _isSubmitting
                        ? 'Queueing publication'
                        : 'Queue RDF publication',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<_PublicationOptions> _loadOptions() async {
    final store = GamelanScope.of(context);
    final classesResult = await store.getOntologyClasses();
    final propertiesResult = await store.getOntologyProperties();

    final classes = switch (classesResult) {
      Success<List<OntologyClass>>(:final value) => value,
      Failure<List<OntologyClass>>(:final message) => throw StateError(message),
    };
    final properties = switch (propertiesResult) {
      Success<List<OntologyProperty>>(:final value) => value,
      Failure<List<OntologyProperty>>(:final message) => throw StateError(
        message,
      ),
    };

    if (classes.isEmpty) {
      throw StateError('The server returned no ontology classes.');
    }

    _selectedOntologyClass ??= _defaultClass(classes);
    return _PublicationOptions(classes: classes, properties: properties);
  }

  void _retryLoadOptions() {
    setState(() {
      _optionsFuture = _loadOptions();
    });
  }

  String _defaultClass(List<OntologyClass> classes) {
    final contributionType = widget.contribution.knowledgeType.trim();
    for (final item in classes) {
      if (item.label.toLowerCase() == contributionType.toLowerCase() ||
          item.entityType.toLowerCase() == contributionType.toLowerCase()) {
        return item.label;
      }
    }
    return classes.first.label;
  }

  void _addRelation() {
    setState(() {
      _relations.add(_RelationDraft());
    });
  }

  void _removeRelation(_RelationDraft relation) {
    setState(() {
      _relations.remove(relation);
      relation.dispose();
    });
  }

  Future<void> _queuePublication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final mapping = OntologyMapping(
      id: 'mobile-mapping-${DateTime.now().microsecondsSinceEpoch}',
      contributionId: widget.contribution.id,
      knowledgeItemId: null,
      ontologyClass: _selectedOntologyClass!.trim(),
      subjectSlug: _subjectSlugController.text.trim(),
      preferredLabel: _preferredLabelController.text.trim(),
      language: _languageController.text.trim(),
      relations: _relations
          .map((relation) => relation.toOntologyRelation())
          .toList(growable: false),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final result = await GamelanScope.of(
      context,
    ).queueRdfPublication(widget.contribution.id, mapping);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });

    switch (result) {
      case Success<RdfPublicationModel>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RDF publication queued.')),
        );
        Navigator.of(context).pop();
      case Failure<RdfPublicationModel>(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _SourceSummaryPreview extends StatelessWidget {
  const _SourceSummaryPreview({required this.contribution});

  final ContributionModel contribution;

  @override
  Widget build(BuildContext context) {
    final summary = contribution.sourceNote.trim().isNotEmpty
        ? contribution.sourceNote.trim()
        : contribution.description.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Source summary preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              summary.isEmpty
                  ? 'The backend will validate required publication source metadata.'
                  : summary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationEditor extends StatelessWidget {
  const _RelationEditor({
    required this.relations,
    required this.classes,
    required this.properties,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_RelationDraft> relations;
  final List<OntologyClass> classes;
  final List<OntologyProperty> properties;
  final VoidCallback onAdd;
  final ValueChanged<_RelationDraft> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Relations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              key: const Key('rdf_add_relation_button'),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add relation'),
            ),
          ],
        ),
        if (relations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('No relation mappings added.'),
          ),
        for (final relation in relations) ...[
          const SizedBox(height: 12),
          _RelationCard(
            relation: relation,
            classes: classes,
            properties: properties,
            onRemove: () => onRemove(relation),
          ),
        ],
      ],
    );
  }
}

class _RelationCard extends StatefulWidget {
  const _RelationCard({
    required this.relation,
    required this.classes,
    required this.properties,
    required this.onRemove,
  });

  final _RelationDraft relation;
  final List<OntologyClass> classes;
  final List<OntologyProperty> properties;
  final VoidCallback onRemove;

  @override
  State<_RelationCard> createState() => _RelationCardState();
}

class _RelationCardState extends State<_RelationCard> {
  @override
  void initState() {
    super.initState();
    widget.relation.property ??= widget.properties.isEmpty
        ? null
        : widget.properties.first.label;
    widget.relation.objectClass ??= widget.classes.isEmpty
        ? null
        : widget.classes.first.label;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Relation mapping',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove relation',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('rdf_relation_property_field'),
              initialValue: widget.relation.property,
              decoration: const InputDecoration(
                labelText: 'Property',
                border: OutlineInputBorder(),
              ),
              items: widget.properties
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.label,
                      child: Text(item.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                widget.relation.property = value;
              },
              validator: (value) => _required(value, 'Select a property.'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('rdf_relation_object_slug_field'),
              controller: widget.relation.objectSlugController,
              decoration: const InputDecoration(
                labelText: 'Object slug',
                border: OutlineInputBorder(),
              ),
              validator: _validateSlug,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('rdf_relation_object_label_field'),
              controller: widget.relation.objectLabelController,
              decoration: const InputDecoration(
                labelText: 'Object label',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _required(value, 'Enter an object label.'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('rdf_relation_object_class_field'),
              initialValue: widget.relation.objectClass,
              decoration: const InputDecoration(
                labelText: 'Object class',
                border: OutlineInputBorder(),
              ),
              items: widget.classes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.label,
                      child: Text(item.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                widget.relation.objectClass = value;
              },
              validator: (value) => _required(value, 'Select an object class.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationOptions {
  const _PublicationOptions({required this.classes, required this.properties});

  final List<OntologyClass> classes;
  final List<OntologyProperty> properties;
}

class _RelationDraft {
  String? property;
  String? objectClass;
  final objectSlugController = TextEditingController();
  final objectLabelController = TextEditingController();

  OntologyRelation toOntologyRelation() {
    return OntologyRelation(
      property: property!.trim(),
      objectSlug: objectSlugController.text.trim(),
      objectLabel: objectLabelController.text.trim(),
      objectClass: objectClass!.trim(),
    );
  }

  void dispose() {
    objectSlugController.dispose();
    objectLabelController.dispose();
  }
}

String? _required(String? value, String message) {
  if (value == null || value.trim().isEmpty) {
    return message;
  }
  return null;
}

String? _validateSlug(String? value) {
  final required = _required(value, 'Enter a slug.');
  if (required != null) {
    return required;
  }
  final normalized = value!.trim();
  final isValid = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(normalized);
  if (!isValid) {
    return 'Use lowercase letters, numbers, and hyphens.';
  }
  return null;
}

String _slugFrom(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'gamelan-knowledge' : normalized;
}

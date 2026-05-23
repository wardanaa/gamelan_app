import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/rdf_publication_model.dart';

void main() {
  test('rdf publication status parses and labels known values', () {
    expect(
      RdfPublicationStatus.fromApiValue('pending'),
      RdfPublicationStatus.pending,
    );
    expect(
      RdfPublicationStatus.fromApiValue('published'),
      RdfPublicationStatus.published,
    );
    expect(
      RdfPublicationStatus.fromApiValue('failed'),
      RdfPublicationStatus.failed,
    );
    expect(
      RdfPublicationStatus.fromApiValue('deprecated'),
      RdfPublicationStatus.deprecated,
    );
    expect(RdfPublicationStatus.failed.label, 'Failed');
  });

  test('rdf publication model parses and roundtrips snake_case data', () {
    final publication = RdfPublicationModel.fromApi({
      'id': 'rdf-publication-uuid',
      'contribution_id': 'contribution-uuid',
      'knowledge_item_id': 'knowledge-item-uuid',
      'ontology_mapping_id': 'ontology-mapping-uuid',
      'rdf_subject_uri': 'https://example.org/gamelan/entity/gangsa',
      'rdf_graph_uri': 'graph/published',
      'status': 'pending',
      'published_at': null,
      'published_by': {'id': 'user-uuid', 'name': 'Made Curator'},
      'error_message': null,
      'metadata': {'ontology_class': 'Instrument', 'relations_count': 1},
      'created_at': '2026-05-22T10:00:00.000000Z',
    });

    expect(publication, isNotNull);
    expect(publication!.status, RdfPublicationStatus.pending);
    expect(publication.publishedBy.name, 'Made Curator');
    expect(publication.metadata['relations_count'], 1);

    final roundTrip = RdfPublicationModel.fromJson(publication.toJson());
    expect(roundTrip, isNotNull);
    expect(roundTrip!.rdfSubjectUri, publication.rdfSubjectUri);
    expect(roundTrip.publishedBy.id, publication.publishedBy.id);
  });

  test(
    'contribution model stays publishable only for approved non-sensitive content',
    () {
      final publishableContribution = ContributionModel.fromApi({
        'id': 'contribution-uuid',
        'title': 'Gangsa in Gong Kebyar',
        'description': 'Validated public description.',
        'status': 'curator_approved',
        'knowledge_type': 'instrument',
        'knowledge_type_label': 'Instrument',
        'gamelan_type': 'gong_kebyar',
        'gamelan_type_label': 'Gong Kebyar',
        'source_note': 'Community interview and local practice note.',
        'contributor_note': 'Submitted as community knowledge.',
        'cultural_sensitivity': false,
        'consent_status': 'granted',
        'created_at': '2026-05-22T10:00:00.000000Z',
      });

      final sensitiveContribution = ContributionModel.fromApi({
        'id': 'sensitive-contribution-uuid',
        'title': 'Restricted note',
        'description': 'Sensitive community practice.',
        'status': 'expert_approved',
        'knowledge_type': 'source',
        'knowledge_type_label': 'Source',
        'gamelan_type': 'gong_gede',
        'gamelan_type_label': 'Gong Gede',
        'source_note': 'Field note',
        'contributor_note': 'Private community note.',
        'cultural_sensitivity': true,
        'consent_status': 'granted',
        'created_at': '2026-05-22T10:00:00.000000Z',
      });

      final draftContribution = ContributionModel.fromApi({
        'id': 'draft-contribution-uuid',
        'title': 'Draft note',
        'description': 'Draft content.',
        'status': 'draft',
        'knowledge_type': 'term',
        'knowledge_type_label': 'Term',
        'gamelan_type': 'gong_kebyar',
        'gamelan_type_label': 'Gong Kebyar',
        'source_note': 'Source note',
        'contributor_note': 'Contributor note.',
        'cultural_sensitivity': false,
        'consent_status': 'granted',
        'created_at': '2026-05-22T10:00:00.000000Z',
      });

      expect(publishableContribution, isNotNull);
      expect(publishableContribution!.isPublishable, isTrue);
      expect(publishableContribution.rdfPublication, isNull);

      expect(sensitiveContribution, isNotNull);
      expect(sensitiveContribution!.isPublishable, isFalse);

      expect(draftContribution, isNotNull);
      expect(draftContribution!.isPublishable, isFalse);
    },
  );

  test('contribution model parses nested rdf publication data', () {
    final contribution = ContributionModel.fromApi({
      'id': 'contribution-uuid',
      'title': 'Gangsa in Gong Kebyar',
      'description': 'Validated public description.',
      'status': 'curator_approved',
      'knowledge_type': 'instrument',
      'knowledge_type_label': 'Instrument',
      'gamelan_type': 'gong_kebyar',
      'gamelan_type_label': 'Gong Kebyar',
      'source_note': 'Community interview and local practice note.',
      'contributor_note': 'Submitted as community knowledge.',
      'cultural_sensitivity': false,
      'consent_status': 'granted',
      'created_at': '2026-05-22T10:00:00.000000Z',
      'rdf_publication': {
        'id': 'rdf-publication-uuid',
        'contribution_id': 'contribution-uuid',
        'ontology_mapping_id': 'ontology-mapping-uuid',
        'rdf_subject_uri': 'https://example.org/gamelan/entity/gangsa',
        'rdf_graph_uri': 'graph/published',
        'status': 'published',
        'published_at': '2026-05-22T11:00:00.000000Z',
        'published_by': {'id': 'user-uuid', 'name': 'Made Curator'},
        'metadata': {'ontology_class': 'Instrument', 'relations_count': 1},
        'created_at': '2026-05-22T10:30:00.000000Z',
      },
    });

    expect(contribution, isNotNull);
    expect(contribution!.rdfPublication, isNotNull);
    expect(contribution.rdfPublication!.status, RdfPublicationStatus.published);

    final roundTrip = ContributionModel.fromJson(contribution.toJson());
    expect(roundTrip, isNotNull);
    expect(roundTrip!.rdfPublication, isNotNull);
    expect(roundTrip.rdfPublication!.publishedBy.name, 'Made Curator');
    expect(roundTrip.isPublishable, isTrue);
  });

  test(
    'contribution model still parses older payloads without rdf publication',
    () {
      final contribution = ContributionModel.fromApi({
        'id': 'older-contribution-uuid',
        'title': 'Gong Gede note',
        'description': 'Validated public description.',
        'status': 'expert_approved',
        'knowledge_type': 'source',
        'knowledge_type_label': 'Source',
        'gamelan_type': 'gong_gede',
        'gamelan_type_label': 'Gong Gede',
        'source_note': 'Field note',
        'contributor_note': 'Community note.',
        'cultural_sensitivity': false,
        'consent_status': 'granted',
        'created_at': '2026-05-22T10:00:00.000000Z',
      });

      expect(contribution, isNotNull);
      expect(contribution!.rdfPublication, isNull);
      expect(contribution.isPublishable, isTrue);
    },
  );
}

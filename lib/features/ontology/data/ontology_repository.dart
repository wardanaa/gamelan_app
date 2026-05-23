import '../../../core/utils/result.dart';
import 'ontology_class.dart';
import 'ontology_entity.dart';
import 'ontology_entity_page.dart';
import 'ontology_property.dart';

abstract class OntologyRepository {
  Future<Result<List<OntologyClass>>> getClasses();

  Future<Result<List<OntologyProperty>>> getProperties();

  Future<Result<OntologyEntityPage>> getEntities({
    String? type,
    int page = 1,
    int perPage = 10,
  });

  Future<Result<OntologyEntity?>> getEntity(String id);
}

import '../../../core/api/api_client.dart';
import 'ontology_entity.dart';

class OntologyEntityPage {
  const OntologyEntityPage({
    required this.entities,
    required this.paginationMeta,
  });

  final List<OntologyEntity> entities;
  final ApiPaginationMeta paginationMeta;

  int get currentPage => paginationMeta.currentPage;
  int get perPage => paginationMeta.perPage;
  int get total => paginationMeta.total;
  bool get hasMore => currentPage * perPage < total;
  bool get isEmpty => entities.isEmpty;
}

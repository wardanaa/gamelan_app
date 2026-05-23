class ApiEndpoints {
  const ApiEndpoints._();

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authLogout = '/auth/logout';
  static const String me = '/me';

  static const String contributions = '/contributions';
  static String contribution(String uuid) => '/contributions/$uuid';
  static String contributionVersions(String uuid) =>
      '/contributions/$uuid/versions';
  static String contributionProvenance(String uuid) =>
      '/contributions/$uuid/provenance';
  static String contributionSubmit(String uuid) =>
      '/contributions/$uuid/submit';
  static String contributionMedia(String uuid) => '/contributions/$uuid/media';
  static String contributionMediaItem(String uuid, String mediaAssetUuid) =>
      '/contributions/$uuid/media/$mediaAssetUuid';

  static const String reviewQueue = '/reviews/queue';
  static String review(String uuid) => '/reviews/$uuid';
  static String reviewApprove(String uuid) => '/reviews/$uuid/approve';
  static String reviewReject(String uuid) => '/reviews/$uuid/reject';
  static String reviewRequestRevision(String uuid) =>
      '/reviews/$uuid/request-revision';
  static String reviewProvenance(String uuid) => '/reviews/$uuid/provenance';
  static String reviewMarkExpertRequired(String uuid) =>
      '/reviews/$uuid/mark-expert-required';
  static String reviewExpertValidate(String uuid) =>
      '/reviews/$uuid/expert-validate';

  static const String knowledgeItems = '/knowledge-items';
  static String knowledgeItem(String id) => '/knowledge-items/$id';
  static String knowledgeItemRelations(String id) =>
      '/knowledge-items/$id/relations';
  static const String knowledgeTypes = '/knowledge-types';
  static const String gamelanTypes = '/gamelan-types';

  static const String search = '/search';

  static const String auditLogs = '/admin/audit-logs';
  static const String users = '/admin/users';
}

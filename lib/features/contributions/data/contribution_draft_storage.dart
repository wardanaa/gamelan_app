import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'contribution_model.dart';

class ContributionDraftStorage {
  ContributionDraftStorage({SharedPreferences? preferences})
    : _preferences = preferences;

  static const storageKey = 'gamelan_contribution_drafts_v1';

  final SharedPreferences? _preferences;

  Future<List<ContributionModel>> loadDrafts() async {
    final preferences = await _instance;
    final encodedDrafts = preferences.getString(storageKey);
    if (encodedDrafts == null || encodedDrafts.isEmpty) {
      return const [];
    }

    try {
      final decodedDrafts = jsonDecode(encodedDrafts);
      if (decodedDrafts is! List<Object?>) {
        return const [];
      }

      return decodedDrafts
          .whereType<Map<String, Object?>>()
          .map(ContributionModel.fromJson)
          .whereType<ContributionModel>()
          .where(_isPersistableDraft)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveDrafts(List<ContributionModel> drafts) async {
    final preferences = await _instance;
    final persistableDrafts = drafts
        .where(_isPersistableDraft)
        .map((draft) => draft.toJson())
        .toList(growable: false);
    await preferences.setString(storageKey, jsonEncode(persistableDrafts));
  }

  Future<SharedPreferences> get _instance async {
    return _preferences ?? SharedPreferences.getInstance();
  }

  static bool _isPersistableDraft(ContributionModel contribution) {
    return contribution.status == ContributionStatus.draft &&
        !contribution.culturalSensitivity;
  }
}

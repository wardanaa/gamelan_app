import 'package:flutter/material.dart';

import 'gamelan_mvp_store.dart';

class GamelanScope extends InheritedNotifier<GamelanMvpStore> {
  const GamelanScope({
    required GamelanMvpStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static GamelanMvpStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GamelanScope>();
    assert(scope != null, 'No GamelanScope found in context.');
    return scope!.notifier!;
  }
}

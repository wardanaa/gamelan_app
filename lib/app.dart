import 'package:flutter/material.dart';

import 'features/contributions/screens/contribution_list_screen.dart';

class GamelanApp extends StatelessWidget {
  const GamelanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamelan App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ContributionListScreen(),
    );
  }
}

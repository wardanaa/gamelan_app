import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/widgets/contribution_card.dart';

void main() {
  testWidgets(
    'contribution card constrains long sensitive content without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final contribution = ContributionModel(
        id: 'sensitive-contribution-uuid',
        title:
            'Very long contribution title about Gong Kebyar practice patterns',
        description:
            'A long contributor description that should remain readable enough '
            'for the list while staying bounded inside the card layout on a '
            'narrow mobile screen without pushing the status badge vertically.',
        status: ContributionStatus.submitted,
        knowledgeType: 'Instrument',
        gamelanType: 'Gong Kebyar',
        sourceNote: 'Community interview and local practice note.',
        contributorNote: 'Contributor context note for curator review.',
        culturalSensitivity: true,
        consentGiven: true,
        createdAt: DateTime(2026, 6, 18),
        allowedActions: const ['view'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ContributionCard(contribution: contribution, onTap: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
    },
  );
}

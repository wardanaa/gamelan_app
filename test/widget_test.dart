import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpMvpApp(
    WidgetTester tester, {
    bool resetPreferences = true,
  }) async {
    if (resetPreferences) {
      SharedPreferences.setMockInitialValues({});
    }
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GamelanApp());
    await tester.pump();
  }

  Future<void> fillRequiredContributionFields(
    WidgetTester tester, {
    required String title,
  }) async {
    await tester.enterText(find.byType(EditableText).at(0), title);
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Local practice note for a non-authoritative contribution draft.',
    );
    await tester.enterText(
      find.byType(EditableText).at(2),
      'Contributor interview summary.',
    );
    await tester.tap(find.text('Contributor consent confirmed'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the MVP app shell and seeded knowledge', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    expect(find.text('Gamelan Knowledge MVP'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Contribute'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search knowledge'), findsOneWidget);
    expect(find.text('Gong Kebyar'), findsWidgets);
    expect(find.text('Gong Gede'), findsWidgets);
    expect(find.text('Gangsa'), findsOneWidget);
  });

  testWidgets('validates contribution form and submits to review queue', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsNWidgets(3));

    await tester.enterText(find.byType(EditableText).at(0), 'Kajar cue note');
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Kajar helps keep a steady pulse in this local practice note.',
    );
    await tester.enterText(
      find.byType(EditableText).at(2),
      'Contributor interview summary.',
    );

    await tester.tap(find.text('Contributor consent confirmed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Culturally sensitive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(find.text('Kajar cue note'), findsOneWidget);
    expect(find.text('Submitted'), findsWidgets);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Kajar cue note'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsWidgets);
  });

  testWidgets('persists non-sensitive local drafts across app recreation', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(
      tester,
      title: 'Persistent gangsa draft',
    );
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Persistent gangsa draft'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpMvpApp(tester, resetPreferences: false);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    expect(find.text('Persistent gangsa draft'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
  });

  testWidgets('does not persist culturally sensitive local drafts', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(
      tester,
      title: 'Sensitive ceremony draft',
    );
    await tester.tap(find.text('Culturally sensitive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Sensitive ceremony draft'), findsOneWidget);
    expect(
      find.text(
        'Sensitive drafts stay in this session only until encrypted storage rules are added.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpMvpApp(tester, resetPreferences: false);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    expect(find.text('Sensitive ceremony draft'), findsNothing);
  });

  testWidgets('does not persist submitted local contributions as drafts', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await fillRequiredContributionFields(
      tester,
      title: 'Submitted reyong note',
    );
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted reyong note'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted reyong note'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpMvpApp(tester, resetPreferences: false);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted reyong note'), findsNothing);
  });

  testWidgets('approved contribution becomes searchable knowledge', (
    WidgetTester tester,
  ) async {
    await pumpMvpApp(tester);

    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New contribution'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Kempli pulse');
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Kempli can mark the pulse in ensemble contexts.',
    );
    await tester.enterText(
      find.byType(EditableText).at(2),
      'Local lesson note.',
    );
    await tester.tap(find.text('Contributor consent confirmed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kempli pulse'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).first,
      'Curator approved.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Kempli pulse'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsWidgets);
  });
}

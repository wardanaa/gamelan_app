import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/app.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const GamelanApp());

    expect(find.text('Contributions'), findsOneWidget);
    expect(find.text('Contribution list'), findsOneWidget);
  });
}

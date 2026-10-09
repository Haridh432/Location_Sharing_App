import 'package:flutter_test/flutter_test.dart';
import 'package:live_location_share/main.dart';

void main() {
  testWidgets('App loads splash and initializes', (WidgetTester tester) async {
    await tester.pumpWidget(const LiveLocationShareApp());
    expect(find.text('Live Location Share'), findsOneWidget);
  });
}

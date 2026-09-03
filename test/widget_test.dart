import 'package:flutter_test/flutter_test.dart';
import 'package:carelens/app.dart';

void main() {
  testWidgets('CareLens app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CareLensApp());

    // Verify that the title and basic shell load
    expect(find.byType(CareLensApp), findsOneWidget);
  });
}

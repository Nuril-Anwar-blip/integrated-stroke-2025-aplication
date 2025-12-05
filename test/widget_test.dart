import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders placeholder widget', (WidgetTester tester) async {
    const placeholder = Placeholder();
    await tester.pumpWidget(const MaterialApp(home: placeholder));
    expect(find.byType(Placeholder), findsOneWidget);
  });
}

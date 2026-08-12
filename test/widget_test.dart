import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visorroute/main.dev.dart';

void main() {
  testWidgets('renders the login screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VisorRouteApp()));
    await tester.pumpAndSettle();

    expect(find.text('VisorRoute'), findsOneWidget);
  });
}

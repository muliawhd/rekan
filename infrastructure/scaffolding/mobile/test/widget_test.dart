import 'package:flutter_test/flutter_test.dart';
import 'package:re_mobile/app.dart';

void main() {
  testWidgets('renders the academic application shell', (tester) async {
    await tester.pumpWidget(const ReApp());

    expect(find.text('Re'), findsOneWidget);
    expect(
      find.text('Find your academic peers.\nFoundation build.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

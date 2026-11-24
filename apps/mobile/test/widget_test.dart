import 'package:flutter_test/flutter_test.dart';
import 'package:re_mobile/app.dart';

void main() {
  testWidgets('unconfigured app shows safe welcome without protected content', (
    tester,
  ) async {
    await tester.pumpWidget(const ReApp());

    expect(find.text('Re:kan'), findsOneWidget);
    expect(find.text('Re'), findsNothing);
    expect(
      find.text('Temukan partner belajar dan rekan kompetisi'),
      findsOneWidget,
    );
    expect(
      find.text('Layanan akun belum dikonfigurasi. Hubungi pengelola Re:kan.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

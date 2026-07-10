import 'package:flutter_test/flutter_test.dart';
import 'package:offer_lab/app.dart';

void main() {
  testWidgets('shows the OfferLab shell', (tester) async {
    await tester.pumpWidget(const OfferLabApp());

    expect(find.text('OfferLab'), findsOneWidget);
    expect(find.text('项目骨架已就绪'), findsOneWidget);
  });
}

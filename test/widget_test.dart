import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qldatlich/main.dart';

void main() {
  testWidgets('QLDATLICH app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const QLDatLichApp() as Widget);

    expect(find.text('QLDATLICH'), findsOneWidget);
  });
}

class QLDatLichApp {
  const QLDatLichApp();
}

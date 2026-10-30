import 'package:flutter_test/flutter_test.dart';
import 'package:qldatlich/main.dart';

void main() {
  testWidgets('QLDATLICH app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminApp());
  });
}

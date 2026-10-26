import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:provider/provider.dart';
import 'package:qldatlich/providers/auth_provider.dart';
import 'package:qldatlich/screens/hospital/guiYeuCauHopTac_Screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Test GuiYeuCauHopTacScreen renders with ZERO overflow on mobile & web',
      (tester) async {
    // Test on a realistic mobile width (390 x 844 - iPhone 12/13/14)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: GuiYeuCauHopTacScreen(
            initialTenBenhVien: 'Bệnh viện An Bình',
            initialDiaChi: '123 Đường An Bình, Q5',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify AppBar
    expect(find.text('Gửi Yêu Cầu Hợp Tác'), findsOneWidget);

    // Verify Hospital Name is read-only
    expect(find.text('Bệnh viện An Bình'), findsOneWidget);

    // Verify Dropdowns exist
    expect(find.text('Bệnh viện Công lập'), findsOneWidget);
    expect(find.text('Có BHYT (Áp dụng BHYT toàn tuyến)'), findsOneWidget);

    // Verify Submit button
    expect(find.text('Gửi Đơn Xác Nhận & Đăng Ký'), findsOneWidget);

    // Verify Location section
    expect(find.text('Tọa độ GPS cơ sở y tế'), findsOneWidget);

    // Now test on large Desktop / Web width (1440 x 900)
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Gửi Yêu Cầu Hợp Tác'), findsOneWidget);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
  });
}

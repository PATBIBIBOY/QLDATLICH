import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

// ✅ 1. IMPORT TẤT CẢ CÁC MÀN HÌNH TAB VÀO ĐÂY
import '../patient/home_screen.dart';
import '../patient/my_appointments_screen.dart';
import '../patient/chat_screen.dart';
import '../patient/notification_screen.dart';
import '../patient/profile_screen.dart';

class PatientMainScreen extends StatefulWidget {
  final int initialIndex;

  const PatientMainScreen({super.key, this.initialIndex = 0});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
  }

  // ✅ 2. KHAI BÁO DANH SÁCH CÁC MÀN HÌNH CẦN CHẠY
  // Chỉ cần gọi tên Class là xong, Flutter sẽ tự quản lý trạng thái (state) của từng màn hình
  final List<Widget> _screens = const [
    HomeScreen(), // Index 0
    MyAppointmentsScreen(showBottomNavBar: false), // Index 1
    ChatScreen(), // Index 2
    NotificationsScreen(), // Index 3
    ProfileScreen(), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ✅ 3. SỬ DỤNG INDEXED STACK ĐỂ GIỮ BOTTOM BAR LUÔN HIỆN
      body: IndexedStack(
        index: _currentIndex,
        children: _screens, // Truyền danh sách màn hình vào đây
      ),

      // ✅ 4. THANH ĐIỀU HƯỚNG
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Chỉ cần thay đổi index, IndexedStack sẽ tự động chuyển màn hình
          setState(() {
            _currentIndex = index;
          });
        },
        notificationCount: 2, // Truyền dữ liệu thực tế vào đây sau này
        chatCount: 1,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/shared_widgets.dart';
import 'home_screen.dart';

// Khung chính: Trang chủ + nút Đăng xuất
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  void _onTap(int i) {
    if (i == 1) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đăng xuất?'),
          content: const Text(
              'Bạn có chắc muốn đăng xuất khỏi tài khoản Admin?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kRed, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đăng xuất (demo)')));
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeScreen(),
      bottomNavigationBar: AdminBottomBar(current: index, onTap: _onTap),
    );
  }
}

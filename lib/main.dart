import 'package:flutter/material.dart';
import 'screens/admin/core/theme.dart';
import 'screens/admin/screens/main_shell.dart';

void main() => runApp(const AdminApp());

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin - Quản trị bệnh viện',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}

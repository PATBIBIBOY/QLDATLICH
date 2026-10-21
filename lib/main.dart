import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qldatlich/hospital_admin.dart' as ha; // chỉ giữ 1 file admin

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';

import 'database_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
=======

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await DatabaseSeeder.seedAllData();
>>>>>>> origin/benhvien

  runApp(const QLDatLichApp());
}

class QLDatLichApp extends StatelessWidget {
  const QLDatLichApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'QLDATLICH',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
<<<<<<< HEAD
        home: ha.MainShell(), // gọi qua prefix ha.
=======
        home: const LoginScreen(),
        // ✅ SỬA LỖI: Bỏ đoạn import bị dính vào đây
>>>>>>> origin/benhvien
        routes: AppRoutes.routes,
      ),
    );
  }
}
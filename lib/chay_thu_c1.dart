import 'package:flutter/material.dart';

import 'models/letan_c1/letan_design_system_c1.dart';
import 'screens/letan_c1/letan_trangchu_screen_c1.dart';

void main() {
  runApp(const KiemThuAppC1());
}

class KiemThuAppC1 extends StatelessWidget {
  const KiemThuAppC1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lễ Tân C1 - Hệ Thống Bệnh Viện',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppDesignSystemC1.primary,
          primary: AppDesignSystemC1.primary,
          surface: AppDesignSystemC1.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppDesignSystemC1.background,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppDesignSystemC1.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppDesignSystemC1.borderRadMedium,
            side: const BorderSide(color: AppDesignSystemC1.border),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const LeTanHomeScreenC1(),
    );
  }
}

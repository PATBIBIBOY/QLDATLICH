import 'package:flutter/material.dart';

// ============ MÀU DÙNG CHUNG ============
const kBg = Color(0xFFF3F4F8);
const kPrimary = Color(0xFF2E7CF6);
const kGreen = Color(0xFF16A34A);
const kGreenBg = Color(0xFFDCFCE7);
const kGreenLight = Color(0xFFEFFDF3);
const kRed = Color(0xFFEF4444);
const kRedBg = Color(0xFFFEF2F2);
const kOrange = Color(0xFFF59E0B);
const kAmber = Color(0xFFD97706);
const kOrangeBg = Color(0xFFFFF7ED);
const kYellowBg = Color(0xFFFFFBEB);

// ============ THEME CHUNG ============
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBg,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
  );
}

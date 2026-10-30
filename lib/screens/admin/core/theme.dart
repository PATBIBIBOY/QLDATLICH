import 'package:flutter/material.dart';

// ============ HỆ THỐNG MÀU SẮC Y TẾ CAO CẤP ============
const kBg = Color(0xFFF8FAFC);          // Nền Slate-50 hiện đại, dịu mắt
const kSurface = Color(0xFFFFFFFF);     // Màu bề mặt Card
const kBorder = Color(0xFFE2E8F0);      // Viền card thanh mảnh

const kPrimary = Color(0xFF1D4ED8);     // Xanh Y Tế đậm chuyên nghiệp (Blue-700)
const kPrimaryLight = Color(0xFFEFF6FF);// Xanh rất nhạt cho highlight
const kPrimaryHover = Color(0xFF1E40AF);

const kGreen = Color(0xFF059669);       // Xanh lục chuẩn thành công / duyệt
const kGreenBg = Color(0xFFD1FAE5);
const kGreenLight = Color(0xFFECFDF5);

const kRed = Color(0xFFDC2626);         // Đỏ cảnh báo / xóa / từ chối
const kRedBg = Color(0xFFFEE2E2);
const kRedLight = Color(0xFFFEF2F2);

const kOrange = Color(0xFFEA580C);      // Cam cảnh báo / báo lỗi
const kAmber = Color(0xFFD97706);
const kOrangeBg = Color(0xFFFFEDD5);
const kYellowBg = Color(0xFFFEF3C7);

const kSlate900 = Color(0xFF0F172A);    // Chữ tiêu đề chính
const kSlate800 = Color(0xFF1E293B);
const kSlate700 = Color(0xFF334155);
const kSlate600 = Color(0xFF475569);    // Chữ phụ
const kSlate500 = Color(0xFF64748B);    // Chữ chú thích
const kSlate400 = Color(0xFF94A3B8);    // Chữ mờ / icon placeholder

// ============ HIỆU ỨNG ĐỔ BÓNG (SOFT SHADOWS) ============
const kCardShadow = [
  BoxShadow(
    color: Color(0x080F172A),
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
];

const kElevatedShadow = [
  BoxShadow(
    color: Color(0x100F172A),
    blurRadius: 20,
    offset: Offset(0, 8),
  ),
];

// ============ THEME TỔNG THỂ ============
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBg,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      surface: kSurface,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kSlate900,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: kSlate900,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
    ),
  );
}

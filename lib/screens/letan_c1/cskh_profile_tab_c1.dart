import 'package:flutter/material.dart';
import 'letan_profile_tab_c1.dart';

/// MÀN HÌNH PROFILE CSKH (RÚT GỌN KẾ THỪA TỪ LETAN_PROFILE_TAB_C1)
/// Giúp loại bỏ hoàn toàn 530 dòng code trùng lặp (DRY Principle)
class CskhProfileTabC1 extends StatelessWidget {
  final VoidCallback? onDangXuat;
  final VoidCallback? onChuyenSangLeTan;

  const CskhProfileTabC1({
    super.key,
    this.onDangXuat,
    this.onChuyenSangLeTan,
  });

  @override
  Widget build(BuildContext context) {
    return LetanProfileTabC1(
      onDangXuat: onDangXuat,
      tenKhoaHienTai: 'Bộ Phận CSKH & Tiếp Nhận',
    );
  }
}

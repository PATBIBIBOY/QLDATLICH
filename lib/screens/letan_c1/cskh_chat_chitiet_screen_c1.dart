import 'package:flutter/material.dart';

import '../../mock/mock_c1/dulieu_mau_cskh_c1.dart';
import '../../models/letan_c1/cskh_model_c1.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';

/// MÀN HÌNH 4: CHI TIẾT ĐOẠN CHAT HỖ TRỢ BỆNH NHÂN (CSKH)
/// Model TinNhanCskhModelC1 chuẩn bị sẵn sàng cho Firebase Collection `tin_nhan`
class CskhChatChitietScreenC1 extends StatefulWidget {
  final HoiThoaiCskhModelC1 hoiThoai;

  const CskhChatChitietScreenC1({
    super.key,
    required this.hoiThoai,
  });

  @override
  State<CskhChatChitietScreenC1> createState() => _CskhChatChitietScreenC1State();
}

class _CskhChatChitietScreenC1State extends State<CskhChatChitietScreenC1> {
  final TextEditingController _noiDungController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<TinNhanCskhModelC1> _danhSachTin;

  @override
  void initState() {
    super.initState();
    _danhSachTin = DuLieuCskhKhoaC1.layTinNhanTheoHoiThoai(widget.hoiThoai.id);
  }

  void _guiTinNhan([String? noiDungGui]) {
    final text = noiDungGui ?? _noiDungController.text.trim();
    if (text.isEmpty) return;

    AppDesignSystemC1.hapticLight();
    setState(() {
      _danhSachTin.add(
        TinNhanCskhModelC1(
          id: 'tn_${DateTime.now().millisecondsSinceEpoch}',
          hoiThoaiId: widget.hoiThoai.id,
          noiDung: text,
          thoiGian: '09:45',
          laCskhGui: true,
        ),
      );
      if (noiDungGui == null) {
        _noiDungController.clear();
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppDesignSystemC1.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF5F5F7),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                _buildCardThongTinBenhNhan(isDark),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _danhSachTin.length,
                    itemBuilder: (context, index) {
                      final item = _danhSachTin[index];
                      return _buildBongBongTinNhan(item, isDark);
                    },
                  ),
                ),
                _buildThanhGoiYNhanh(isDark),
                _buildThanhNhapTinNhan(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header chi tiết chat
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.hoiThoai.vietTat,
              style: const TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hoiThoai.hoTen,
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.hoiThoai.tuoi} tuổi • ${widget.hoiThoai.khoa}',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'BHYT',
              style: TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ thông tin hồ sơ bệnh nhân
  Widget _buildCardThongTinBenhNhan(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.4) : const Color(0xFFE8F4FD),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFBAE6FD),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 15, color: Color(0xFF0284C7)),
              SizedBox(width: 6),
              Text(
                'Thông tin bệnh nhân',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'BHYT: ${widget.hoiThoai.maBhyt} • Lịch khám gần nhất: 18/09 • BS. Vũ Nam Tuấn',
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF334155),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // Bong bóng tin nhắn Chat
  Widget _buildBongBongTinNhan(TinNhanCskhModelC1 item, bool isDark) {
    final isMe = item.laCskhGui;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF0284C7)
                : (isDark ? AppDesignSystemC1.darkSurface : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: isMe ? null : Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.noiDung,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E)),
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.thoiGian,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : const Color(0xFF8E8E93),
                      fontSize: 10.5,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_rounded, size: 12, color: Colors.white70),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Thanh gợi ý trả lời nhanh
  Widget _buildThanhGoiYNhanh(bool isDark) {
    final goiYNhanh = DuLieuCskhKhoaC1.goiYTraLoiNhanh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý trả lời nhanh:',
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: goiYNhanh.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final goiY = goiYNhanh[index];
                return InkWell(
                  onTap: () => _guiTinNhan(goiY),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C2444) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF0284C7)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      goiY,
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Thanh nhập tin nhắn
  Widget _buildThanhNhapTinNhan(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _noiDungController,
                decoration: InputDecoration(
                  hintText: 'Nhập phản hồi cho bệnh nhân...',
                  hintStyle: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFFAEAEB2),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _guiTinNhan(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _guiTinNhan(),
            icon: const Icon(Icons.send_rounded),
            color: const Color(0xFF0284C7),
          ),
        ],
      ),
    );
  }
}

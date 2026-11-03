import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/lichhen_model.dart';
import '../../models/phong_kham_model.dart';
import '../../models/review_model.dart';
import '../../providers/lich_hen_provider.dart';
import '../../providers/review_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/booking_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class AppTheme {
  // Constructor private để ngăn chặn việc khởi tạo class này
  AppTheme._();

  // --- Màu sắc ---
  static const Color bgColor = Color(0xFFF7F7F8);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF5B8C3E);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  // --- Cấu hình ---
  static const int soNgayHienThi = 6;
}

// ──────────────────────────────────────────────────────────────
// 1. HEADER & INFO
// ──────────────────────────────────────────────────────────────

class AppointmentHeader extends StatelessWidget {
  final Color textDark;
  final VoidCallback onBack;

  const AppointmentHeader({
    super.key,
    required this.textDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.grey.shade100,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back_ios_new, size: 16),
              ),
            ),
          ),
          Text(
            'Điền thông tin đặt lịch',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(width: 36), // Cân bằng layout
        ],
      ),
    );
  }
}

class HospitalInfoCard extends StatelessWidget {
  final Map<String, dynamic> hospitalData;
  final Color primaryBlue;
  final Color primaryGreen;
  final Color textDark;
  final Color textGrey;

  const HospitalInfoCard({
    super.key,
    required this.hospitalData,
    required this.primaryBlue,
    required this.primaryGreen,
    required this.textDark,
    required this.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    final hospitalName =
        hospitalData['ten_benh_vien']?.toString() ?? 'Tên bệnh viện';
    final hospitalAddress = hospitalData['dia_chi']?.toString() ?? 'Địa chỉ';
    final ratingValue =
        hospitalData['diem_danh_gia_tb'] ?? hospitalData['diem_danh_gia'];
    final hospitalRating = ratingValue is num
        ? ratingValue.toDouble()
        : double.tryParse(ratingValue?.toString() ?? '') ?? 0;
    final reviewCountValue =
        hospitalData['tong_so_danh_gia'] ?? hospitalData['so_luong_danh_gia'];
    final reviewCount = reviewCountValue is num
        ? reviewCountValue.toInt()
        : int.tryParse(reviewCountValue?.toString() ?? '') ?? 0;

    final facilityValue =
        (hospitalData['co_so'] ?? hospitalData['co_so_id'] ?? '')
            .toString()
            .toLowerCase();
    final isPublic = facilityValue == 'cong_lap' || facilityValue == 'công lập';
    final isPrivate = facilityValue == 'tu_nhan' || facilityValue == 'tư nhân';
    final facilityLabel = isPublic
        ? 'Bệnh viện công'
        : isPrivate
        ? 'Bệnh viện tư'
        : 'Chưa cập nhật loại cơ sở';
    final facilityColor = isPublic
        ? primaryBlue
        : isPrivate
        ? const Color(0xFFD97706)
        : textGrey;
    final facilityBackground = isPublic
        ? const Color(0xFFE3F2FD)
        : isPrivate
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFF1F1F1);

    final bhytValue = (hospitalData['bhyt'] ?? hospitalData['bhyt_id'] ?? '')
        .toString()
        .toLowerCase();
    final hasBhyt =
        bhytValue == 'co_bhyt' || bhytValue == 'có bhyt' || bhytValue == 'true';
    final noBhyt = bhytValue == 'khong_bhyt' || bhytValue == 'không bhyt';
    final bhytColor = hasBhyt
        ? primaryGreen
        : noBhyt
        ? const Color(0xFFB42318)
        : textGrey;
    final bhytText = hasBhyt
        ? 'Bệnh viện có hỗ trợ khám BHYT'
        : noBhyt
        ? 'Bệnh viện không hỗ trợ khám BHYT'
        : 'Chưa cập nhật thông tin BHYT';
    final bhytIcon = hasBhyt
        ? Icons.check_circle_rounded
        : noBhyt
        ? Icons.cancel_rounded
        : Icons.info_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      facilityBackground,
                      Color.lerp(facilityBackground, Colors.white, 0.5)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  size: 30,
                  color: facilityColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: facilityBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            facilityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: facilityColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: hospitalRating > 0
                                ? const Color(0xFFFFF8E1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: hospitalRating > 0
                                    ? const Color(0xFFFFA000)
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hospitalRating > 0
                                    ? hospitalRating.toStringAsFixed(1)
                                    : 'Chưa có đánh giá',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: hospitalRating > 0
                                      ? textDark
                                      : textGrey,
                                ),
                              ),
                              if (hospitalRating > 0 && reviewCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '($reviewCount)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    hospitalAddress,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bhytColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bhytColor.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(bhytIcon, size: 22, color: bhytColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bhytText,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: bhytColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingInfoBox extends StatelessWidget {
  const BookingInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: green, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13.5, color: green, height: 1.45),
                children: [
                  TextSpan(text: 'Vui lòng chọn '),
                  TextSpan(
                    text: 'Chuyên khoa',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ', '),
                  TextSpan(
                    text: 'Phòng khám',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' và '),
                  TextSpan(
                    text: 'Ngày khám',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' phù hợp. Lịch sẽ được '),
                  TextSpan(
                    text: 'xét duyệt',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 2. SPECIALTY & ROOM SELECTION
// ──────────────────────────────────────────────────────────────

class SpecialtySelectionSection extends StatelessWidget {
  final int selectedCount;
  final List<String> selectedNames;
  final bool isExpanded;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> departments;
  final Set<String> selectedDepartmentIds;
  final VoidCallback onToggleExpand;
  final Function(String) onToggleDepartment;

  const SpecialtySelectionSection({
    super.key,
    required this.selectedCount,
    required this.selectedNames,
    required this.isExpanded,
    required this.isLoading,
    this.error,
    required this.departments,
    required this.selectedDepartmentIds,
    required this.onToggleExpand,
    required this.onToggleDepartment,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2196F3);
    const textDark = Color(0xFF1A1A1A);
    const textGrey = Color(0xFF757575);
    const borderColor = Color(0xFFE0E0E0);

    Widget messageBox(IconData icon, String text, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
          TextSpan(
            text: 'Chọn chuyên khoa khám',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggleExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryBlue, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      size: 20,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: selectedCount == 0
                        ? const Text(
                            'Chọn chuyên khoa',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: textGrey,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đã chọn ($selectedCount)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedNames.isEmpty
                                    ? '$selectedCount chuyên khoa'
                                    : selectedNames.join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 26,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !isExpanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : error != null
                          ? messageBox(
                              Icons.error_outline_rounded,
                              error!,
                              Colors.redAccent,
                            )
                          : departments.isEmpty
                          ? messageBox(
                              Icons.search_off_rounded,
                              'Bệnh viện chưa có danh sách chuyên khoa.',
                              Colors.grey.shade400,
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 340),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: departments.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: borderColor),
                                itemBuilder: (context, index) {
                                  final department = departments[index];
                                  final departmentId =
                                      BookingHelper.departmentIdOf(department);
                                  final name =
                                      department['ten_khoa']?.toString() ??
                                      'Chuyên khoa';
                                  final description =
                                      department['mo_ta']?.toString() ?? '';
                                  final isSelected = selectedDepartmentIds
                                      .contains(departmentId);

                                  return Material(
                                    color: isSelected
                                        ? primaryBlue.withOpacity(0.07)
                                        : Colors.white,
                                    child: InkWell(
                                      onTap: () =>
                                          onToggleDepartment(departmentId),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? primaryBlue
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? primaryBlue
                                                      : Colors.grey.shade400,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? primaryBlue.withOpacity(
                                                        0.14,
                                                      )
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons
                                                    .health_and_safety_outlined,
                                                size: 21,
                                                color: isSelected
                                                    ? primaryBlue
                                                    : textGrey,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isSelected
                                                          ? primaryBlue
                                                          : textDark,
                                                    ),
                                                  ),
                                                  if (description
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      description,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        height: 1.3,
                                                        color: textGrey,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class BookingStepTitle extends StatelessWidget {
  final int step;
  final String text;
  const BookingStepTitle({super.key, required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF2196F3),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class RoomSelectionList extends StatelessWidget {
  final String activeId;
  final bool isLoading;
  final String? error;
  final List<PhongKhamModel> rooms;
  final String? selectedRoomId;
  final Function(String, String) onSelect;
  final Function(String, {bool force}) onRetry;

  const RoomSelectionList({
    super.key,
    required this.activeId,
    required this.isLoading,
    this.error,
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2196F3);
    const borderColor = Color(0xFFE0E0E0);
    const textGrey = Color(0xFF757575);
    const textDark = Color(0xFF1A1A1A);

    Widget infoBox(IconData icon, String text, Color color, {Widget? action}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: textGrey,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      );
    }

    if (isLoading)
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    if (error != null)
      return infoBox(
        Icons.error_outline_rounded,
        error!,
        Colors.redAccent,
        action: TextButton(
          onPressed: () => onRetry(activeId, force: true),
          child: const Text('Thử lại'),
        ),
      );
    if (rooms.isEmpty)
      return infoBox(
        Icons.meeting_room_outlined,
        'Chuyên khoa này chưa có phòng khám.',
        Colors.grey.shade400,
      );

    return Column(
      children: List.generate(rooms.length, (i) {
        final room = rooms[i];
        final roomId = BookingHelper.roomIdOf(room);
        final subtitle = BookingHelper.roomSubtitleOf(room);
        final isSelected = selectedRoomId == roomId;

        return Padding(
          padding: EdgeInsets.only(bottom: i == rooms.length - 1 ? 0 : 10),
          child: Material(
            color: isSelected ? primaryBlue.withOpacity(0.07) : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? primaryBlue : borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => onSelect(activeId, roomId),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryBlue.withOpacity(0.14)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        size: 22,
                        color: isSelected ? primaryBlue : textGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            BookingHelper.roomNameOf(room),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? primaryBlue : textDark,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? primaryBlue : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? primaryBlue
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 3. DATE & TIME SELECTION
// ──────────────────────────────────────────────────────────────

class DateTimeSelectionSection extends StatelessWidget {
  final List<String> selectedIds;
  final String? activeId;
  final String? selectedRoomId;
  final DateTime? selectedDay;
  final int doneCount;
  final List<Map<String, dynamic>> days;
  final LichHenProvider lichHen;
  final CaSlotModel? selectedSlot;
  final DateTime labelDate;
  final String monthLabel;
  final String hospitalId;
  final List<Map<String, dynamic>> departments;
  final List<PhongKhamModel> rooms;
  final bool isLoadingRooms;
  final String? roomError;
  final Function(String, {bool force}) onRetryFetch;

  final Function(String, String) onRoomSelected;
  final Function(String, String, DateTime) onDaySelected;
  final Function(String, String) onOpenCalendar;
  final String Function(String) getDepartmentName;
  final String Function(String, String) getRoomName;
  final String Function(DateTime) formatDayMonth;
  final int Function(String, String) getRoomMax;
  final Function(String, String, String) onSlotSelected;
  final Function(String) onSwitchActiveDepartment;

  const DateTimeSelectionSection({
    super.key,
    required this.selectedIds,
    required this.activeId,
    required this.selectedRoomId,
    required this.selectedDay,
    required this.doneCount,
    required this.days,
    required this.lichHen,
    required this.selectedSlot,
    required this.labelDate,
    required this.monthLabel,
    required this.hospitalId,
    required this.departments,
    required this.onRoomSelected,
    required this.onDaySelected,
    required this.onOpenCalendar,
    required this.getDepartmentName,
    required this.getRoomName,
    required this.formatDayMonth,
    required this.getRoomMax,
    required this.rooms,
    required this.isLoadingRooms,
    this.roomError,
    required this.onRetryFetch,
    required this.onSlotSelected,
    required this.onSwitchActiveDepartment,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2196F3);
    const primaryGreen = Color(0xFF5B8C3E);
    const textDark = Color(0xFF1A1A1A);
    const textGrey = Color(0xFF757575);
    const borderColor = Color(0xFFE0E0E0);

    final titleWidget = const Text.rich(
      TextSpan(
        text: 'Chọn phòng khám, ngày và khung giờ khám',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );

    if (activeId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 30,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa chọn chuyên khoa',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hãy chọn chuyên khoa ở trên để chọn phòng khám,\nngày và khung giờ khám.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.4, color: textGrey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleWidget,
        const SizedBox(height: 10),
        if (selectedIds.length > 1) ...[
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final id = selectedIds[i];
                final isActive = id == activeId;
                final isDone = _hasScheduleFor(
                  id,
                  selectedRoomId,
                  selectedDay,
                  selectedSlot,
                ); // Simplified check for UI
                return GestureDetector(
                  onTap: () => onSwitchActiveDepartment(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isActive ? primaryBlue : borderColor,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 17,
                          color: isActive
                              ? Colors.white
                              : (isDone ? primaryGreen : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            getDepartmentName(id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã chọn lịch cho $doneCount/${selectedIds.length} khoa',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: doneCount == selectedIds.length ? primaryGreen : textGrey,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      size: 20,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch khám của',
                          style: TextStyle(fontSize: 11.5, color: textGrey),
                        ),
                        Text(
                          getDepartmentName(activeId!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const BookingStepTitle(step: 1, text: 'Chọn phòng khám'),
              const SizedBox(height: 10),
              RoomSelectionList(
                activeId: activeId!,
                isLoading: isLoadingRooms,
                error: roomError,
                rooms: rooms,
                selectedRoomId: selectedRoomId,
                onSelect: onRoomSelected,
                onRetry: onRetryFetch,
              ),
              if (selectedRoomId == null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock_rounded, size: 18, color: textGrey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hãy chọn phòng khám để xem ngày và khung giờ khám.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 14),
                const BookingStepTitle(step: 2, text: 'Chọn ngày khám'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onOpenCalendar(activeId!, selectedRoomId!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: primaryBlue,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Xem lịch tháng',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 78,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final date = days[i]['date'] as DateTime;
                      final isSelected =
                          selectedDay != null &&
                          BookingHelper.isSameDay(date, selectedDay!);
                      return GestureDetector(
                        onTap: () =>
                            onDaySelected(activeId!, selectedRoomId!, date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 66,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryBlue,
                                      primaryBlue.withOpacity(0.75),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? primaryBlue : borderColor,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                days[i]['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : textGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                days[i]['day'] as String,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 14),
                const BookingStepTitle(step: 3, text: 'Khung giờ khám'),
                const SizedBox(height: 10),

                SlotSelectionList(
                  activeId: activeId!,
                  roomId: selectedRoomId!,
                  selectedDay: selectedDay,
                  lichHen: lichHen,
                  hospitalId: hospitalId,
                  getRoomMax: getRoomMax,
                  onSlotSelected: onSlotSelected,
                  selectedCaId: selectedSlot?.caId,
                ),

                if (selectedDay != null && selectedSlot != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đã chọn: ${getRoomName(activeId!, selectedRoomId!)} · ngày ${formatDayMonth(selectedDay!)} · ${selectedSlot!.tenCa} (${selectedSlot!.gioBatDau} - ${selectedSlot!.gioKetThuc})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _hasScheduleFor(
    String id,
    String? roomId,
    DateTime? day,
    CaSlotModel? slot,
  ) {
    return roomId != null && day != null && slot != null;
  }
}

class SlotSelectionList extends StatelessWidget {
  final String activeId;
  final String roomId;
  final DateTime? selectedDay;
  final LichHenProvider lichHen;
  final String hospitalId;
  final String? selectedCaId;
  final int Function(String, String) getRoomMax;
  final Function(String, String, String) onSlotSelected;

  const SlotSelectionList({
    super.key,
    required this.activeId,
    required this.roomId,
    required this.selectedDay,
    required this.lichHen,
    required this.hospitalId,
    required this.getRoomMax,
    required this.onSlotSelected,
    required this.selectedCaId,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2196F3);
    const primaryGreen = Color(0xFF5B8C3E);
    const textGrey = Color(0xFF757575);
    const textDark = Color(0xFF1A1A1A);
    const borderColor = Color(0xFFE0E0E0);

    // 1. Chưa chọn ngày
    if (selectedDay == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 30, color: textGrey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hãy chọn ngày khám để xem các khung giờ còn trống.',
                style: TextStyle(fontSize: 13, height: 1.4, color: textGrey),
              ),
            ),
          ],
        ),
      );
    }

    final key = BookingHelper.slotKeyFor(
      departmentId: activeId,
      roomId: roomId,
      date: selectedDay!,
      hospitalId: hospitalId,
    );
    final error = lichHen.slotsErrorOf(key);

    // 2. Lỗi tải dữ liệu
    if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 30,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => lichHen.loadSlots(
                      ngay: selectedDay!,
                      benhVienId: hospitalId,
                      khoaId: activeId,
                      phongKhamId: roomId,
                      soBenhNhanToiDa: getRoomMax(activeId, roomId),
                      force: true,
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Đang tải
    if (lichHen.isLoadingSlots(key) || !lichHen.hasLoadedSlots(key)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final slots = lichHen.slotsOf(key);

    // 4. Không có ca nào trong ngày này
    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_busy_rounded, size: 30, color: textGrey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Phòng khám chưa có lịch khám vào ngày này.\nVui lòng chọn ngày khác.',
                style: TextStyle(fontSize: 13, height: 1.4, color: textGrey),
              ),
            ),
          ],
        ),
      );
    }

    // 5. Hiển thị danh sách ca khám
    return Column(
      children: List.generate(slots.length, (i) {
        final slot = slots[i];
        final left = slot.conLai;
        final total = slot.tongSo;
        final isUnknownTotal = total <= 0;
        final isFull = !isUnknownTotal && left <= 0;

        // Lấy selectedSlot từ provider để so sánh (hoặc bạn có thể truyền selectedCaId xuống)
        final isSelected = selectedCaId == slot.caId;

        final color = isUnknownTotal
            ? primaryGreen
            : BookingHelper.availabilityColor(left, total);
        final isMorning =
            slot.caId.toLowerCase().contains('sang') ||
            slot.tenCa.toLowerCase().contains('sáng');

        return Padding(
          padding: EdgeInsets.only(bottom: i == slots.length - 1 ? 0 : 10),
          child: Opacity(
            opacity: isFull ? 0.55 : 1.0,
            child: Material(
              color: isSelected ? primaryBlue.withOpacity(0.07) : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? primaryBlue : borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: isFull
                    ? null
                    : () => onSlotSelected(activeId, roomId, slot.caId),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isMorning
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isMorning
                                  ? Icons.wb_sunny_rounded
                                  : Icons.wb_twilight_rounded,
                              size: 22,
                              color: isMorning
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.tenCa,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? primaryBlue : textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${slot.gioBatDau} - ${slot.gioKetThuc}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? primaryBlue
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? primaryBlue
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? left / total : 1,
                                minHeight: 6,
                                backgroundColor: color.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isFull
                                ? 'Hết chỗ'
                                : isUnknownTotal
                                ? 'Còn trống'
                                : 'Còn $left/$total chỗ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 4. LOCATION & REVIEW (Rút gọn để fit trong giới hạn, bạn có thể copy nguyên bản từ code cũ vào đây)
// ──────────────────────────────────────────────────────────────

class LocationSection extends StatelessWidget {
  final Map<String, dynamic> hospitalData;
  const LocationSection({super.key, required this.hospitalData});

  @override
  Widget build(BuildContext context) {
    final latitudeValue = hospitalData['vi_do'];
    final longitudeValue = hospitalData['kinh_do'];
    final latitude = latitudeValue is num
        ? latitudeValue.toDouble()
        : double.tryParse(latitudeValue?.toString() ?? '');
    final longitude = longitudeValue is num
        ? longitudeValue.toDouble()
        : double.tryParse(longitudeValue?.toString() ?? '');
    final hasCoordinates = latitude != null && longitude != null;
    final hospitalName =
        hospitalData['ten_benh_vien']?.toString() ?? 'Bệnh viện';
    final hospitalAddress =
        hospitalData['dia_chi']?.toString() ?? 'Địa chỉ chưa cập nhật';

    Future<void> openGoogleMaps() async {
      if (!hasCoordinates) {
        context.showAppSnackBar(
          title: 'Thiếu tọa độ bản đồ',
          message: 'Bệnh viện chưa có tọa độ bản đồ',
          type: SnackBarType.warning,
        );
        return;
      }
      final uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
      });
      try {
        var launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched)
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!launched && context.mounted) {
          context.showAppSnackBar(
            title: 'Không thể mở bản đồ',
            message: 'Không thể mở bản đồ',
            type: SnackBarType.error,
          );
        }
      } catch (error) {
        if (context.mounted)
          context.showAppSnackBar(
            title: 'Không thể mở bản đồ',
            message: 'Không thể mở bản đồ',
            type: SnackBarType.error,
          );
      }
    }

    Future<void> copyAddress() async {
      await Clipboard.setData(ClipboardData(text: hospitalAddress));
      if (context.mounted) {
        context.showAppSnackBar(
          title: 'Sao chép thành công',
          message: 'Đã sao chép địa chỉ',
          type: SnackBarType.success,
          duration: const Duration(seconds: 2),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.map_rounded,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Vị trí bệnh viện',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                SizedBox(
                  height: 176,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: openGoogleMaps,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: MiniMapPainter(
                              accent: AppTheme.primaryBlue,
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, -0.12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE53935,
                                        ).withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(
                                  width: 3,
                                  height: 10,
                                  child: ColoredBox(color: Color(0xFFE53935)),
                                ),
                                Container(
                                  width: 16,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasCoordinates
                                        ? Icons.place_rounded
                                        : Icons.location_off_rounded,
                                    size: 15,
                                    color: hasCoordinates
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textGrey,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      hasCoordinates
                                          ? hospitalName
                                          : 'Chưa có tọa độ bản đồ',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: hasCoordinates
                                      ? [
                                          AppTheme.primaryBlue,
                                          AppTheme.primaryBlue.withOpacity(
                                            0.82,
                                          ),
                                        ]
                                      : [
                                          Colors.grey.shade500,
                                          Colors.grey.shade400,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      hasCoordinates ? 0.35 : 0,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Chỉ đường',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Địa chỉ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hospitalAddress,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sao chép địa chỉ',
                        onPressed: copyAddress,
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 19,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewSection extends StatefulWidget {
  final String? activeId;
  final Set<String> selectedDepartmentIds;
  final String hospitalId;
  final List<Map<String, dynamic>> departments;
  final String Function(String) getDepartmentName;

  const ReviewSection({
    super.key,
    required this.activeId,
    required this.selectedDepartmentIds,
    required this.hospitalId,
    required this.departments,
    required this.getDepartmentName,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState(); // ✅ CHỈ GIỮ LẠI 1 STATE NÀY
}

class _ReviewSectionState extends State<ReviewSection> {
  int _selectedStar = 5;
  int _reviewVisibleCount = 5;

  @override
  void initState() {
    super.initState();
    _loadReviewsForActive();
  }

  @override
  void didUpdateWidget(covariant ReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId) {
      setState(() {
        _selectedStar = 5;
        _reviewVisibleCount = 5;
      });
      _loadReviewsForActive(force: true);
    }
  }

  void _loadReviewsForActive({bool force = false}) {
    final provider = context.read<ReviewProvider>();
    final id = widget.activeId;

    if (id == null ||
        id.isEmpty ||
        !widget.selectedDepartmentIds.contains(id)) {
      provider.clearReviews();
      return;
    }

    if (widget.hospitalId.isEmpty) {
      return;
    }

    provider.fetchReviews(
      hospitalId: widget.hospitalId,
      khoaId: id,
      force: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDepartment =
        widget.activeId != null &&
        widget.selectedDepartmentIds.contains(widget.activeId);

    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final total = reviewProvider.totalCount;
        final counts = reviewProvider.countByStar;
        final starReviews = reviewProvider.reviewsByStar(_selectedStar);
        final visible = starReviews.take(_reviewVisibleCount).toList();

        const avatarColors = [
          Color(0xFFBBDEFB),
          Color(0xFFFFE0B2),
          Color(0xFFC8E6C9),
          Color(0xFFE1BEE7),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Đánh giá và nhận xét',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (hasDepartment)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.getDepartmentName(widget.activeId!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── CÁC TRẠNG THÁI HIỂN THỊ ──
            if (!hasDepartment)
              _buildReviewMessage(
                Icons.touch_app_rounded,
                'Hãy chọn chuyên khoa để xem đánh giá của khoa đó.',
                AppTheme.primaryBlue,
              )
            else if (reviewProvider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (reviewProvider.error != null)
              _buildReviewMessage(
                Icons.error_outline_rounded,
                reviewProvider.error!,
                Colors.redAccent,
                onRetry: () => _loadReviewsForActive(force: true),
              )
            else if (total == 0)
              _buildReviewMessage(
                Icons.rate_review_outlined,
                'Chưa có đánh giá nào cho chuyên khoa này.',
                AppTheme.textGrey,
              )
            else ...[
              _buildReviewSummary(reviewProvider.averageRating, total, counts),
              const SizedBox(height: 16),
              Row(
                children: [5, 4, 3, 2, 1]
                    .map(
                      (star) => _buildStarTab(
                        star: star,
                        count: counts[star] ?? 0,
                        selected: star == _selectedStar,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey<int>(_selectedStar),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: starReviews.isEmpty
                      ? <Widget>[
                          _buildReviewMessage(
                            Icons.star_border_rounded,
                            'Chưa có đánh giá $_selectedStar sao nào.',
                            AppTheme.textGrey,
                          ),
                        ]
                      : List<Widget>.generate(visible.length, (index) {
                          final review = visible[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visible.length - 1 ? 0 : 12,
                            ),
                            child: _buildReviewCard(
                              name: review.displayName,
                              rating: review.diemDanhGia,
                              comment: review.nhanXet,
                              avatarText: BookingHelper.reviewerInitial(review),
                              avatarColor:
                                  avatarColors[index % avatarColors.length],
                              timeAgo: BookingHelper.getTimeAgo(review.ngayTao),
                            ),
                          );
                        }),
                ),
              ),
              if (starReviews.length > visible.length) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _reviewVisibleCount += 5),
                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                    label: Text(
                      'Xem thêm ${starReviews.length - visible.length} đánh giá',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(
                        color: AppTheme.primaryBlue.withOpacity(0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  // ── CÁC HÀM HỖ TRỢ REVIEW ──
  Widget _buildReviewMessage(
    IconData icon,
    String text,
    Color color, {
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppTheme.textGrey,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSummary(double average, int total, Map<int, int> counts) {
    const amber = Color(0xFFFFA000);
    const orange = Color(0xFFFF7043);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4D6), Color(0xFFFFFBF0)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: amber.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: amber.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 108,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 38,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                BookingHelper.starRow(average, size: 15, center: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    BookingHelper.ratingLabelOfAverage(average),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total đánh giá',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = counts[star] ?? 0;
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                        child: Text(
                          '$star',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.star_rounded, size: 12, color: amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: amber.withOpacity(0.16),
                              ),
                              FractionallySizedBox(
                                widthFactor: fraction.clamp(0.0, 1.0),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [amber, orange],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarTab({
    required int star,
    required int count,
    required bool selected,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: star == 1 ? 0 : 8),
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedStar = star;
            _reviewVisibleCount = 5;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withOpacity(0.78),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppTheme.primaryBlue : AppTheme.borderColor,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$star',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : (count == 0
                                  ? AppTheme.textGrey
                                  : AppTheme.textDark),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: selected
                          ? Colors.white
                          : (count == 0
                                ? Colors.grey.shade400
                                : const Color(0xFFFFA000)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.25)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String name,
    required int rating,
    required String comment,
    required String avatarText,
    required Color avatarColor,
    required String timeAgo,
  }) {
    final chipText = BookingHelper.ratingChipText(rating);
    final chipColor = BookingHelper.ratingChipColor(rating);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      avatarColor,
                      Color.lerp(avatarColor, Colors.white, 0.45)!,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withOpacity(0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        BookingHelper.starRow(rating.toDouble(), size: 15),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chipText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chipColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(
                    color: AppTheme.primaryBlue.withOpacity(0.55),
                    width: 3,
                  ),
                ),
              ),
              // ✅ Đảm bảo bạn đã đổi tên _ExpandableText thành ExpandableText (không có dấu gạch dưới) ở file widget
              child: ExpandableText(
                text: comment.trim(),
                accent: AppTheme.primaryBlue,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BookingBottomActionArea extends StatelessWidget {
  final Color primaryGreen;
  final VoidCallback onContinue;
  const BookingBottomActionArea({
    super.key,
    required this.primaryGreen,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tiếp tục đặt lịch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MiniMapPainter extends CustomPainter {
  final Color accent;
  const MiniMapPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFEBE3),
    );
    const cols = 6;
    const rows = 4;
    final cw = w / cols;
    final ch = h / rows;
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9;
    for (var c = 0; c <= cols; c++)
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, h), roadPaint);
    for (var r = 0; r <= rows; r++)
      canvas.drawLine(Offset(0, r * ch), Offset(w, r * ch), roadPaint);
    final blockPaint = Paint()..color = const Color(0xFFE4DFD3);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cw + 8, r * ch + 8, cw - 16, ch - 16),
            const Radius.circular(6),
          ),
          blockPaint,
        );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.12, w * 0.22, h * 0.34),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFCDE7C2),
    );
    final river = Path()
      ..moveTo(w * 0.66, -10)
      ..cubicTo(w * 0.56, h * 0.3, w * 0.84, h * 0.6, w * 0.74, h + 10);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFBFDDF3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
    final avenue = Path()
      ..moveTo(-10, h * 0.78)
      ..lineTo(w + 10, h * 0.3);
    canvas.drawPath(
      avenue,
      Paint()
        ..color = const Color(0xFFD9D3C5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );
    canvas.drawPath(
      avenue,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    final route = Path()
      ..moveTo(w * 0.08, h * 0.96)
      ..cubicTo(w * 0.3, h * 0.84, w * 0.3, h * 0.66, w * 0.5, h * 0.6);
    final routePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final metric in route.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 10),
          routePaint,
        );
        distance += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color accent;
  const ExpandableText({
    super.key,
    required this.text,
    required this.style,
    required this.accent,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  static const int _collapsedLines = 3;
  static const int _longThreshold = 140;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > _longThreshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: (_expanded || !isLong) ? null : _collapsedLines,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          ),
        ),
        if (isLong)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _expanded ? 'Thu gọn' : 'Xem thêm',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: widget.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

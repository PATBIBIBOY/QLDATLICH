import '../../models/letan_c1/letan_model_c1.dart';

// Du lieu mau chay offline cho Le tan C1
class DuLieuMauLeTanC1 {
  static const String tenKhoaMacDinh = 'Khoa Tim Mạch';
  static const String tenLeTan = 'Đinh Hoàng Cước';

  static const ThongKeLeTanC1 thongKe = ThongKeLeTanC1(
    daTiepNhan: 47,
    dangCho: 12,
    daKham: 35,
  );

  static const List<BenhNhanChoKhamC1> danhSachCho = [
    BenhNhanChoKhamC1(
      id: 'BN01',
      ten: 'Nguyễn Văn An',
      khoa: 'Khoa Tim mạch',
      gioKham: '08:30',
      trangThai: 'Tiếp theo',
      avatarInitials: 'NA',
    ),
    BenhNhanChoKhamC1(
      id: 'BN02',
      ten: 'Trần Thị Hoa',
      khoa: 'Khoa Tim mạch',
      gioKham: '09:00',
      trangThai: 'Đang chờ',
      avatarInitials: 'TH',
    ),
    BenhNhanChoKhamC1(
      id: 'BN03',
      ten: 'Lê Minh',
      khoa: 'Khoa Tim mạch',
      gioKham: '09:15',
      trangThai: 'Chưa đến',
      avatarInitials: 'LM',
    ),
    BenhNhanChoKhamC1(
      id: 'BN04',
      ten: 'Phạm Hồng Nhung',
      khoa: 'Khoa Tim mạch',
      gioKham: '09:30',
      trangThai: 'Đang chờ',
      avatarInitials: 'HN',
    ),
  ];

  static const List<ThongBaoLeTanC1> danhSachThongBao = [
    ThongBaoLeTanC1(
      id: 'TB01',
      tieuDe: 'Phòng khám 204 mở thêm ca khám',
      noiDungNgan: 'BS. CKII Lê Hoàng Nam tăng cường nhận thêm 5 bệnh nhân ca sáng.',
      noiDungChiTiet: 'Do số lượng bệnh nhân khám tim mạch đầu tuần tăng cao, phòng khám 204 (Tầng 2 - Khu A) sẽ mở thêm 05 số thứ tự từ 16 đến 20 cho các bệnh nhân đặt lịch hẹn trực tuyến. Lễ tân vui lòng hướng dẫn bệnh nhân quét mã QR để lấy số ưu tiên.',
      thoiGian: '08:15 - Hôm nay',
      loai: 'lich_hen',
      daDoc: false,
    ),
    ThongBaoLeTanC1(
      id: 'TB02',
      tieuDe: 'Hệ thống gọi số tự động đã bảo trì xong',
      noiDungNgan: 'Màn hình hiển thị số phòng 201 - 205 đã đồng bộ dữ liệu thời gian thực.',
      noiDungChiTiet: 'Đội ngũ kỹ thuật IT bệnh viện đã hoàn tất cập nhật phần mềm gọi số tự động tại sảnh chờ. Hiện tượng lệch số thứ tự trên màn hình đã được khắc phục hoàn toàn. Lễ tân có thể vận hành quầy tiếp đón bình thường.',
      thoiGian: '07:45 - Hôm nay',
      loai: 'he_thong',
      daDoc: false,
    ),
    ThongBaoLeTanC1(
      id: 'TB03',
      tieuDe: 'Ưu tiên tiếp nhận bệnh nhân cấp cứu / người cao tuổi',
      noiDungNgan: 'Khoa Tim mạch tiếp nhận 02 ca chuyển tuyến từ phòng cấp cứu.',
      noiDungChiTiet: 'Đề nghị bàn tiếp đón lễ tân hỗ trợ thủ tục phân luồng nhanh cho bệnh nhân chuyển tuyến từ cấp cứu và bệnh nhân trên 75 tuổi có thẻ BHYT theo đúng quy trình ưu tiên của bệnh viện.',
      thoiGian: '16:30 - Hôm qua',
      loai: 'khan_cap',
      daDoc: true,
    ),
    ThongBaoLeTanC1(
      id: 'TB04',
      tieuDe: 'Lịch bàn giao ca trực chiều 09/10/2026',
      noiDungNgan: 'Ca trực chiều sẽ bắt đầu lúc 13:00 tại quầy lễ tân sảnh A.',
      noiDungChiTiet: 'Nhân viên lễ tân ca sáng Đinh Hoàng Cước hoàn tất thống kê số lượng bệnh nhân đã tiếp nhận trước 12:00 và bàn giao sổ nhật ký tiếp đón cho nhân viên ca chiều đúng quy định.',
      thoiGian: '14:00 - Hôm qua',
      loai: 'nhan_su',
      daDoc: true,
    ),
  ];
}

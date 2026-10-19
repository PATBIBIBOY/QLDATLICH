# GHI CHÚ KIẾN TRÚC & NGUYÊN TẮC DỮ LIỆU - PHÂN HỆ C1 (LỄ TÂN & CSKH)
*Người phụ trách: Đinh Hoàng Cước (C1)*
*Dự án: DoAnChuyenDe - Đặt Lịch Khám*

---

## 📌 NGUYÊN TẮC THIẾT KẾ DATABASE (FIRESTORE)

Thay vì lưu toàn bộ thông tin của ứng dụng vào một Document hoặc một mảng dữ liệu lớn, Database được chia thành nhiều Collection độc lập theo từng chức năng.

### 🎯 Mục đích tổ chức:
1. **Giảm lượng dữ liệu không cần thiết** tải về thiết bị người dùng.
2. **Giảm mức sử dụng bộ nhớ và tài nguyên** của ứng dụng.
3. **Tăng tốc độ truy xuất** và hiển thị thông tin.
4. **Dễ dàng quản lý, bảo trì và mở rộng** hệ thống.
5. **Cho phép từng chức năng truy xuất dữ liệu độc lập.**
6. **Hạn chế việc đọc toàn bộ Database** khi chỉ cần một phần dữ liệu.

---

## ⚖️ NGUYÊN TẮC CHÍNH (CORE PRINCIPLES)

> **Chức năng nào cần dữ liệu gì thì chỉ truy xuất dữ liệu đó.**

* Hệ thống được thiết kế theo hướng **phân chia dữ liệu thành nhiều Collection độc lập**, sử dụng **Document** để quản lý từng đối tượng và **liên kết thông qua ID**.
* Cách thiết kế này giúp giảm lượng dữ liệu truyền về thiết bị, hạn chế truy xuất không cần thiết, cải thiện hiệu suất và tạo điều kiện thuận lợi cho việc phát triển ứng dụng.

---

## 🔑 NGUYÊN TẮC XUYÊN SUỐT CỦA DỰ ÁN

> **Không tải toàn bộ dữ liệu khi người dùng chỉ cần sử dụng một phần nhỏ của hệ thống.**

---

## 📝 ỨNG DỤNG CỤ THỂ CHO PHÂN HỆ C1 (LỄ TÂN & CSKH):
- **Phần Lễ tân:** Chỉ truy xuất dữ liệu ca trực, thông tin nhân viên đăng nhập hiện tại và danh sách lịch khám cần xử lý/check-in theo ngày. Không tải toàn bộ lịch sử khám toàn viện hay hồ sơ bệnh án không liên quan.
- **Phần CSKH:** Chỉ truy xuất danh sách đơn chờ duyệt thuộc khoa/chuyên khoa phụ trách và danh sách đoạn chat đang tương tác.
- **Liên kết dữ liệu:** Sử dụng `ma_nhan_vien`, `ma_benh_nhan`, `lich_hen_id` để kết nối giữa các Collection thay vì nhúng gộp dữ liệu khổng lồ vào một chỗ.
 ạo dữ liệu lịch hẹn mẫu ngày 25/10/2026 trên Firestore chuẩn cấu trúc bệnh viện
Trạng thái: ĐÃ LÀM XONG TRÊN DATABASE
Chi tiết: Đã chạy script ghi trực tiếp vào Firestore datlichkham-37558 theo đúng phân cấp: /LichHen/2026-10-25/ca/{ca_id}/benh_vien/BV001/khoa/{khoa_id}/phong_kham/.../benh_nhan/.../lich_hen/...
Đã có dữ liệu của:
Khoa Tim (K001): 4 bệnh nhân (Nguyễn Văn An, Trần Thị Mai, Lê Hoàng Phúc, Phạm Minh Quang).
Khoa Mắt (K003): 2 bệnh nhân (Võ Thị Hồng, Đặng Tuấn Kiệt).
Khoa Nhi (K004): 1 bệnh nhân (Bé Nguyễn Gia Hân).
2. Cho phép Lễ tân và CSKH chọn ngày (DatePicker) để xem lịch hẹn
Trạng thái: ĐÃ LÀM XONG GIAO DIỆN & LOGIC TRUYỀN NGÀY
Chi tiết:
Lễ tân (Trang chủ): Đã thêm nút bấm chọn ngày kèm biểu tượng lịch ở mục Thống kê lịch khám, bấm vào mở showDatePicker.
Lễ tân (Tab Lịch hẹn): Đã thay dòng ngày tĩnh thành nút chọn ngày (như trong ảnh bạn chụp đã hiện Ngày 25/10/2026).
CSKH (Danh sách duyệt đơn): Đã tích hợp nút chọn ngày ngay trên thanh tiến độ duyệt đơn để nhân viên CSKH chọn ngày cần duyệt.
3. Đọc dữ liệu từ Firebase, không dùng hardcode
Trạng thái: ĐÃ CHUYỂN TOÀN BỘ SANG STREAM FIREBASE
Chi tiết: Toàn bộ dữ liệu hiển thị (Thống kê, danh sách chờ, danh sách lịch hẹn) đã chuyển sang gọi FirebaseServiceC1.streamDanhSachLichHen và FirebaseServiceC1.streamThongKeHomNay.
4. Logic Duyệt / Từ chối đơn khám (Lưu trực tiếp lên Firebase)
Trạng thái: ĐÃ VIẾT XONG HÀM CẬP NHẬT DATABASE
Chi tiết:
Hàm _duyetDon() và _tuChoiHetTatCa() đã được gắn chính xác đường dẫn document docPath để khi bấm nút ✓ hoặc ✕ sẽ ghi đè trường trang_thai_id (2: đã duyệt, 4: từ chối) lên đúng document đó trên Firestore.
⚠️ Điểm duy nhất ĐANG BỊ VƯỚNG (như trong ảnh bạn gửi):
Dữ liệu trên database đã có, giao diện chọn ngày đã có, nhưng trên màn hình của bạn vẫn hiện "0 lịch hẹn".
Lý do: Tên khoa trên màn hình đang để chữ "Khoa Tim Mạch" nhưng trong database lưu là "KHOA TIM", dẫn đến bộ lọc so sánh tên khoa bị lệch và chưa hiển thị ra danh sách cho bạn bấm duyệt.
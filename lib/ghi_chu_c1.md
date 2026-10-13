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

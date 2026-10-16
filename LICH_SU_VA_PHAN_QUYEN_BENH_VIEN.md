# BÁO CÁO LỊCH SỬ CHỈNH SỬA & QUY ĐỊNH PHẠM VI TRUY CẬP FILE
**Phân hệ phụ trách:** Bệnh viện (Cơ sở y tế) & Tạo Bệnh viện  
**Dự án:** QLDATLICH (`https://github.com/PATBIBIBOY/QLDATLICH/tree/benhvien`)  
**Ngày cập nhật:** 16/10/2026  

---

## I. LỊCH SỬ CÁC FILE ĐÃ CHỈNH SỬA & TẠO MỚI

| STT | Đường dẫn File | Loại thay đổi | Chi tiết thao tác | Trạng thái Git |
| :---: | :--- | :---: | :--- | :---: |
| **1** | `lib/screens/hospital/addKhoaHospital_Screen.dart` | Sửa đổi | Loại bỏ các thư viện import không sử dụng (`app_routes.dart`, `cloud_firestore.dart`) nhằm loại sạch warning linter của Flutter. | Đã commit & push (`fc35a09`) |
| **2** | `lib/screens/auth/email_verification_screen.dart` | Sửa đổi | Thêm kiểm tra an toàn `if (!mounted) return;` ngay sau `await authProvider.markEmailAsVerified();` để khắc phục lỗi bất đồng bộ `use_build_context_synchronously`. | Đã commit & push (`fc35a09`) |
| **3** | `lib/main_hospital.dart` | Đã xóa | Bỏ hoàn toàn file chạy riêng `main_hospital.dart`, chuyển sang chạy chung thống nhất duy nhất qua `lib/main.dart`. | Đã xóa |
| **4** | `lib/config/app_routes.dart` | Sửa đổi | Liên kết route `hospitalDashboard` trực tiếp đến `HomeHospitalScreen` (`homeHospital_Screem.dart`). | Đang ở local |
| **5** | `lib/config/app_session.dart` | Sửa đổi | Bỏ `const` của `benhVienId` để hệ thống gán động theo UID của từng tài khoản Bệnh viện đăng nhập. | Đang ở local |
| **6** | `lib/providers/auth_provider.dart` | Sửa đổi | Hỗ trợ `preferredRole` trong `fetchCurrentUser` và `login` để ưu tiên load hồ sơ bệnh viện và gán `AppSession.benhVienId`. | Đang ở local |
| **7** | `lib/screens/hospital/homeHospital_Screem.dart` | Sửa đổi | Tích hợp Firebase Firestore realtime: Render giao diện Bệnh viện mới tạo chưa duyệt theo mẫu ảnh; tự động đồng bộ khi Admin duyệt; hỗ trợ gửi đơn xác nhận hợp tác lên `BenhVien` & `YeuCauHopTac`. | Đang ở local |
| **8** | `lib/screens/auth/login_screen.dart` | Sửa đổi | Kết nối luồng đăng nhập vai trò Bệnh viện: Kiểm tra tài khoản trong Firestore `BenhVien/{uid}`, thiết lập `AppSession.benhVienId`, chuyển thẳng sang `HomeHospitalScreen`. | Đang ở local |

> **Thông tin Commit đã đẩy lên nhánh `benhvien`:**
> * `b4b964d` - *có đn/dk*
> * `7e2bea2` - *cap nhat nôi dung dk/dn,*
> * `fc35a09` - *fix: loai bo unused imports va bo sung mounted check*

---

## II. MA TRẬN PHÂN QUYỀN TRUY CẬP FILE (THEO ĐẶC TẢ SDS)

Nhằm đảm bảo làm việc nhóm không gây xung đột (conflict) mã nguồn và tuân thủ chặt chẽ ranh giới nhiệm vụ:

```
                                  KIẾN TRÚC HỆ THỐNG
   ┌──────────────────────────────────────┬─────────────────────────────────────┐
   │        PHẠM VI ĐƯỢC PHÉP             │            CÁC VAI TRÒ KHÁC         │
   │       (PHÂN HỆ BỆNH VIỆN)            │        (KHÔNG TỰ Ý CHỈNH SỬA)       │
   ├──────────────────────────────────────┼─────────────────────────────────────┤
   │ • lib/screens/hospital/*             │ • lib/screens/patient/*             │
   │ • lib/services/benhVien_service.dart │ • lib/screens/admin/*               │
   │ • lib/services/khoa_service.dart     │ • lib/screens/receptionist/*        │
   │ • lib/models/hospital_model.dart     │ • lib/screens/doctor_assistant/*    │
   │ • lib/main_hospital.dart             │ • lib/screens/customer_support/*    │
   └──────────────────────────────────────┴─────────────────────────────────────┘
```

### 1. Khu vực ĐƯỢC PHÉP làm việc toàn quyền (Phân hệ Bệnh viện)
Bạn được toàn quyền thêm, sửa, tái cấu trúc logic và giao diện cho các file sau:
* **Giao diện Bệnh viện (`lib/screens/hospital/`):**
  * `homeHospital_Screem.dart` (Trang chủ Bệnh viện, thẻ thống kê, danh sách khoa)
  * `addKhoaHospital_Screen.dart` (Màn hình thêm khoa khám mới & phòng khám)
  * `chiTietKhoa_screem.dart` (Màn hình chi tiết khoa và điều phối trạng thái phòng khám)
  * `listKhoaDieuTri.dart` (Danh sách và bộ lọc tìm kiếm các khoa)
  * `CapTK_Scream.dart` (Cấp tài khoản nhân viên cho bệnh viện)
  * `hospital_dashboard.dart`, `staff_management_screen.dart`, `statistics_screen.dart`
* **Dịch vụ & Dữ liệu Bệnh viện:**
  * `lib/services/benhVien_service.dart` (Xử lý thông tin và thống kê bệnh viện)
  * `lib/services/khoa_service.dart` (Xử lý Firestore batch tạo khoa và phòng)
  * `lib/models/hospital_model.dart` (Model dữ liệu bệnh viện)
  * `lib/main_hospital.dart` (File chạy độc lập phân hệ bệnh viện)

---

### 2. Khu vực CẤM ĐỤNG VÀO (Thuộc vai trò của thành viên khác)

> **CẢNH BÁO:** Tuyệt đối không chỉnh sửa hoặc xóa code trong các thư mục dưới đây để tránh đè code (overwrite) của đồng đội:

| Phân hệ / Vai trò | Thư mục & File trực thuộc | Trách nhiệm chính |
| :--- | :--- | :--- |
| **Bệnh nhân (Patient)** | • `lib/screens/patient/*`<br>• `lib/models/patient_model.dart`<br>• `lib/models/appointment_model.dart`<br>• `lib/models/doctor_model.dart`<br>• `lib/models/medical_record_model.dart`<br>• `lib/providers/booking_provider.dart`<br>• `lib/widgets/doctor_card.dart`, `appointment_card.dart` | Đặt lịch khám, theo dõi kết quả, lịch sử khám bệnh, nhận mã QR, đánh giá bệnh viện. |
| **Quản trị viên (Admin)** | • `lib/screens/admin/*`<br>• `lib/database_seeder.dart` | Duyệt bệnh viện tham gia hệ thống, quản lý tài khoản admin, cấu hình hệ thống, chạy seed data. |
| **Lễ tân (Receptionist)** | • `lib/screens/receptionist/*` | Quét mã QR tiếp đón bệnh nhân tại sảnh quầy, xác nhận vào hàng đợi của khoa. |
| **Hỗ trợ bác sĩ (Assistant)**| • `lib/screens/doctor_assistant/*` | Điều phối gọi số thứ tự khám, cập nhật hồ sơ bệnh án sau khi khám. |
| **CSKH (Customer Support)** | • `lib/screens/customer_support/*`<br>• `lib/providers/chat_provider.dart` | Trả lời tin nhắn hỗ trợ bệnh nhân, tiếp nhận và xử lý khiếu nại/ticket. |

---

### 3. Khu vực DÙNG CHUNG (Shared / Core) - Cần thỏa thuận trước khi sửa
Các file này dùng chung cho toàn bộ app, chỉ chỉnh sửa khi có sự thống nhất giữa các thành viên:
* `lib/main.dart` *(Khởi chạy toàn ứng dụng)*
* `lib/config/app_routes.dart` *(Đăng ký danh mục đường dẫn điều hướng màn hình)*
* `lib/config/constants.dart` *(Mã vai trò `Role`, trạng thái `TrangThaiId`, tên collection Firestore)*
* `lib/config/app_theme.dart` & `lib/config/firebase_options.dart`
* `lib/providers/auth_provider.dart` & `lib/services/auth_service.dart` *(Logic xác thực Đăng nhập/Đăng ký)*
* `lib/screens/auth/*` *(Các màn hình đăng nhập, đăng ký, quên mật khẩu dùng chung)*

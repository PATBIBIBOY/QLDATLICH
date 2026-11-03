const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// ✅ KHỞI TẠO FIREBASE ADMIN SDK MỘT LẦN DUY NHẤT CHO TOÀN BỘ FILE
admin.initializeApp();

// ========================================================================
// HÀM 1: Lắng nghe sự kiện CẬP NHẬT trạng thái lịch hẹn (Giữ nguyên)
// ========================================================================
exports.onLichHenStatusChanged = onDocumentUpdated("LichHen/{lichHenId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (beforeData.trang_thai_id === afterData.trang_thai_id) {
    return null;
  }

  const benhNhanId = afterData.benh_nhan_id;
  const newStatus = String(afterData.trang_thai_id);

  const benhVienId = afterData.benh_vien_id || "";
  const khoaId = afterData.khoa_id || "";
  const tenBenhVien = afterData.ten_benh_vien || "Bệnh viện";
  const tenKhoa = afterData.ten_khoa || "Khoa";
  const tenPhongKham = afterData.ten_phong_kham || "phòng khám được chỉ định";
  const lichHenId = event.params.lichHenId;

  let tieuDe = "";
  let noiDung = "";
  let loaiThongBao = "";

  if (newStatus === "2") {
    loaiThongBao = "benh_vien_xac_nhan";
    tieuDe = "Lịch hẹn đã được xác nhận";
    noiDung = "Lịch khám tại " + tenKhoa + " - " + tenBenhVien + " của bạn đã được duyệt thành công.";
  } else if (newStatus === "4") {
    loaiThongBao = "benh_vien_huy_lich";
    tieuDe = "Lịch hẹn của bạn đã bị hủy";
    noiDung = "Rất tiếc, lịch khám tại " + tenKhoa + " - " + tenBenhVien + " đã bị hủy. Vui lòng đặt lịch mới.";
  } else if (newStatus === "5") {
    loaiThongBao = "benh_vien_thong_bao";
    tieuDe = "Khám bệnh hoàn thành";
    noiDung = "Cảm ơn bạn đã hoàn thành quy trình khám tại " + tenKhoa + " - " + tenBenhVien + ". Hãy dành chút thời gian đánh giá trải nghiệm của bạn!";
  } else if (newStatus === "7") {
    loaiThongBao = "benh_vien_nhan_nho";
    tieuDe = "Cảnh báo trễ giờ khám";
    noiDung = "Bạn đã đến trễ so với giờ hẹn ban đầu. Vui lòng di chuyển đến " + tenPhongKham + " sớm nhất để được hỗ trợ xếp vào hàng chờ.";
  } else {
    return null;
  }

  const thongBaoId = "TB_" + loaiThongBao + "_" + Date.now();
  const ngayTao = admin.firestore.Timestamp.now();

  try {
    const notificationRef = admin.firestore()
      .collection("ThongBao")
      .doc(benhNhanId)
      .collection("danh_sach")
      .doc(thongBaoId);

    await notificationRef.set({
      thong_bao_id: thongBaoId,
      benh_nhan_id: benhNhanId,
      loai_thong_bao: loaiThongBao,
      tieu_de: tieuDe,
      noi_dung: noiDung,
      lich_hen_id: lichHenId,
      benh_vien_id: benhVienId,
      khoa_id: khoaId,
      ten_benh_vien: tenBenhVien,
      ten_khoa: tenKhoa,
      ngay_tao: ngayTao,
      da_doc: false,
    });

    const userDoc = await admin.firestore().collection("BenhNhan").doc(benhNhanId).get();
    const userData = userDoc.data();
    const fcmToken = userData ? userData.fcm_token : null;

    if (fcmToken) {
      const message = {
        notification: { title: tieuDe, body: noiDung },
        data: {
          type: "LICH_HEN_UPDATE",
          lichHenId: lichHenId,
          screen: "appointment_detail",
        },
        token: fcmToken,
        android: {
          priority: "high",
          notification: { sound: "default", channelId: "lich_hen_channel" }
        },
        apns: { payload: { aps: { sound: "default" } } },
      };

      await admin.messaging().send(message);
      console.log("✅ Đã gửi FCM thành công cho bệnh nhân:", benhNhanId);
    } else {
      console.log("⚠️ Bệnh nhân chưa có FCM Token:", benhNhanId);
    }
  } catch (error) {
    console.error("❌ Lỗi trong Cloud Function (onLichHenStatusChanged):", error);
  }

  return null;
});


// ========================================================================
// HÀM 2: Chạy theo lịch để nhắc lịch khám vào ngày mai (ĐÃ SỬA MÚI GIỜ)
// ========================================================================
// Việt Nam = UTC+7, không có giờ mùa hè
const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
 
/**
 * Trả về khoảng [start, end) của "ngày mai" theo giờ Việt Nam,
 * dưới dạng Date (thời điểm UTC thực sự).
 */
function getTomorrowRangeVN() {
  const vnNow = new Date(Date.now() + VN_OFFSET_MS);
 
  // 00:00 ngày mai (giờ VN), tính bằng các trường UTC của vnNow
  const tomorrowStartAsUTC = Date.UTC(
    vnNow.getUTCFullYear(),
    vnNow.getUTCMonth(),
    vnNow.getUTCDate() + 1,
    0, 0, 0, 0
  );
 
  // Trừ offset để ra thời điểm UTC thực sự
  const start = new Date(tomorrowStartAsUTC - VN_OFFSET_MS);
  const end = new Date(start.getTime() + DAY_MS);
  return { start, end };
}
 
exports.remindAppointmentTomorrow = onSchedule(
  {
    schedule: "50 0 * * *", // Chạy lúc 23:50 giờ VN
    timeZone: "Asia/Ho_Chi_Minh",
  },
  async () => {
    console.log("⏰ Bắt đầu kiểm tra lịch khám cho ngày mai...");
 
    try {
      const db = admin.firestore();
      const { start, end } = getTomorrowRangeVN();
 
      console.log(
        `🔍 Query ngay_dat từ ${start.toISOString()} đến ${end.toISOString()} (UTC)`
      );
 
      // Chỉ query theo khoảng ngày (không cần composite index),
      // lọc trạng thái ở phía code để chấp nhận cả number 2 và string "2".
      const snapshot = await db
        .collection("LichHen")
        .where("ngay_dat", ">=", admin.firestore.Timestamp.fromDate(start))
        .where("ngay_dat", "<", admin.firestore.Timestamp.fromDate(end))
        .get();
 
      const appointments = snapshot.docs.filter(
        (doc) => Number(doc.data().trang_thai_id) === 2
      );
 
      console.log(
        `✅ Tìm thấy ${appointments.length}/${snapshot.size} lịch hẹn (trạng thái 2) cho ngày mai.`
      );
 
      for (const doc of appointments) {
        const data = doc.data();
        const benhNhanId = data.benh_nhan_id;
        if (!benhNhanId) continue;
 
        const tenKhoa = data.ten_khoa || "Khoa";
        const tenBenhVien = data.ten_benh_vien || "Bệnh viện";
        const tenPhongKham = data.ten_phong_kham || "Phòng khám";
        const soThuTu = data.so_thu_tu ? `#${data.so_thu_tu}` : "Chưa có";
        const gioKham = data.gio_du_kien || data.gio_bat_dau || "giờ đã định";
 
        // ID cố định theo lịch hẹn: chạy lại hàm sẽ ghi đè, không tạo thông báo trùng
        const thongBaoId = `TB_REMIND_${doc.id}`;
 
        try {
          // 1. Lưu vào tab Thông báo
          await db
            .collection("ThongBao")
            .doc(benhNhanId)
            .collection("danh_sach")
            .doc(thongBaoId)
            .set({
              thong_bao_id: thongBaoId,
              benh_nhan_id: benhNhanId,
              loai_thong_bao: "benh_vien_nhan_nho",
              tieu_de: "Nhắc lịch khám ngày mai",
              noi_dung: `Bạn có lịch khám tại ${tenKhoa} vào lúc ${gioKham}. Hãy sử dụng tính năng "Theo dõi lịch khám" trong app.`,
              lich_hen_id: doc.id,
              benh_vien_id: data.benh_vien_id || null,
              khoa_id: data.khoa_id || null,
              ngay_tao: admin.firestore.FieldValue.serverTimestamp(),
              da_doc: false,
            });
 
          // 2. Gửi Push Notification
          const userDoc = await db.collection("BenhNhan").doc(benhNhanId).get();
          const fcmToken = userDoc.data()?.fcm_token;
 
          if (!fcmToken) {
            console.warn(`⚠️ Bệnh nhân ${benhNhanId} chưa có FCM Token.`);
            continue;
          }
 
          await admin.messaging().send({
            notification: {
              title: "🔔 Nhắc lịch khám ngày mai!",
              body: `Chào bạn, bạn có lịch khám tại ${tenKhoa} (${tenPhongKham}) - ${tenBenhVien} vào lúc ${gioKham}. Số thứ tự: ${soThuTu}.\n\n💡 Hãy bấm vào để theo dõi trực tiếp khi nào đến lượt bạn nhé!`,
            },
            data: {
              type: "APPOINTMENT_REMINDER",
              screen: "appointment_tracking",
              lichHenId: doc.id,
            },
            token: fcmToken,
            android: {
              priority: "high",
              notification: {
                sound: "default",
                channelId: "appointment_reminder_channel",
              },
            },
            apns: { payload: { aps: { sound: "default" } } },
          });
 
          console.log(`✅ Đã gửi nhắc lịch cho bệnh nhân: ${benhNhanId}`);
        } catch (error) {
          console.error(`❌ Lỗi xử lý nhắc lịch ${doc.id}:`, error);
        }
      }
    } catch (error) {
      console.error("❌ Lỗi khi gửi nhắc lịch (remindAppointmentTomorrow):", error);
    }
  }
);

exports.requeueLatePatient = onCall(async (request) => {
  // 1. Kiểm tra xác thực (chỉ cho phép role 'ho_tro_bac_si' hoặc admin)
  if (!request.auth) throw new Error("Unauthorized: Bạn không có quyền thực hiện thao tác này.");

  const { lichHenId, targetStt, phongKhamId, ngayDatStr } = request.data;

  if (!lichHenId || targetStt === undefined || !phongKhamId || !ngayDatStr) {
    throw new Error("Thiếu dữ liệu bắt buộc để sắp xếp lại.");
  }

  const db = admin.firestore();
  const ngayDat = admin.firestore.Timestamp.fromDate(new Date(ngayDatStr));
  const newStt = targetStt + 1; // STT mới của bệnh nhân đến trễ

  try {
    await db.runTransaction(async (transaction) => {
      // 2. Lấy thông tin bệnh nhân đến trễ
      const latePatientRef = db.collection("LichHen").doc(lichHenId);
      const latePatientDoc = await transaction.get(latePatientRef);

      if (!latePatientDoc.exists) {
        throw new Error("Không tìm thấy lịch hẹn.");
      }

      // 3. Cập nhật trực tiếp STT mới và đổi trạng thái về '2' (Đang chờ khám)
      transaction.update(latePatientRef, {
        so_thu_tu: newStt,
        trang_thai_id: "2",
        ngay_cap_nhat: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 4. Tìm tất cả bệnh nhân ĐANG CHỜ ('2') trong cùng phòng/ngày 
      // mà có STT >= STT mới của bệnh nhân đến trễ
      const activePatientsQuery = db.collection("LichHen")
        .where("phong_kham_id", "==", phongKhamId)
        .where("ngay_dat", "==", ngayDat)
        .where("trang_thai_id", "==", "2")
        .where("so_thu_tu", ">=", newStt);

      const activePatientsSnapshot = await activePatientsQuery.get();

      // 5. Tăng STT của họ lên 1 (trừ chính bệnh nhân vừa được cập nhật ở bước 3)
      const batch = db.batch(); // Dùng batch trong transaction để tối ưu
      activePatientsSnapshot.docs.forEach((doc) => {
        if (doc.id !== lichHenId) {
          transaction.update(doc.ref, {
            so_thu_tu: admin.firestore.FieldValue.increment(1),
          });
        }
      });
    });

    return { success: true, message: `Đã sắp xếp bệnh nhân vào sau số ${targetStt} (STT mới: ${newStt}). Các số phía sau đã được đẩy lên.` };
  } catch (error) {
    console.error("Lỗi khi chèn hàng:", error);
    throw new Error(error.message);
  }
});
 
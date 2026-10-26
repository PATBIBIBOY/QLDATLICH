import 'package:flutter_test/flutter_test.dart';
import 'package:qldatlich/models/hospital_model.dart';

void main() {
  test('HospitalModel serialization and deserialization with id and maBenhVien', () {
    // 1. Test fromMap with docId BV500
    final rawData500 = {
      'ten_benh_vien': 'Cơ sở y tế 500',
      'email': 'csyt500@gmail.com',
      'trang_thai_hop_tac_id': '10',
      'tong_so_danh_gia': '259',
      'diem_danh_gia_tb': 4.6,
    };
    final model500 = HospitalModel.fromMap(rawData500, 'BV500');
    expect(model500.id, 500);
    expect(model500.maBenhVien, 'BV500');
    expect(model500.uid, 'BV500');
    expect(model500.trangThaiHopTacId, 10);
    expect(model500.tongSoDanhGia, 259);

    // 2. Test new hospital creation (e.g. BV501)
    final newModel = HospitalModel.fromRegisterEmail(
      id: 501,
      maBenhVien: 'BV501',
      uid: 'BV501',
      authUid: 'firebase_auth_uid_xyz',
      tenBenhVien: 'Bệnh viện Đa Khoa Quốc Tế',
      email: 'bvquocte501@gmail.com',
      diaChi: '123 Đường ABC',
    );

    expect(newModel.id, 501);
    expect(newModel.maBenhVien, 'BV501');
    expect(newModel.uid, 'BV501');
    expect(newModel.authUid, 'firebase_auth_uid_xyz');

    // 3. Test toMap()
    final map = newModel.toMap();
    expect(map['id'], 501);
    expect(map['ma_benh_vien'], 'BV501');
    expect(map['uid'], 'BV501');
    expect(map['auth_uid'], 'firebase_auth_uid_xyz');

    // 4. Test re-creating fromMap
    final restored = HospitalModel.fromMap(map, 'BV501');
    expect(restored.id, 501);
    expect(restored.maBenhVien, 'BV501');
    expect(restored.uid, 'BV501');
    expect(restored.authUid, 'firebase_auth_uid_xyz');
    expect(restored.tenBenhVien, 'Bệnh viện Đa Khoa Quốc Tế');

    // 5. Test next auto increment logic: 501 -> 502
    final nextId = restored.id! + 1;
    final nextMaBv = 'BV${nextId.toString().padLeft(3, '0')}';
    expect(nextId, 502);
    expect(nextMaBv, 'BV502');

    print('✅ Tất cả kiểm thử unit test cho HospitalModel và ID tăng dần đã passed thành công!');
  });
}

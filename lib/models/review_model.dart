import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String benhNhanId;
  final int diemDanhGia;
  final String nhanXet;
  final bool anDanh;
  final DateTime ngayTao;

  ReviewModel({
    required this.id,
    required this.benhNhanId,
    required this.diemDanhGia,
    required this.nhanXet,
    required this.anDanh,
    required this.ngayTao,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json, String docId) {
    return ReviewModel(
      id: docId,
      benhNhanId: json['benh_nhan_id'] ?? '',
      diemDanhGia: (json['diem_danh_gia'] as num?)?.toInt() ?? 0,
      nhanXet: json['nhan_xet'] ?? '',
      anDanh: (json['an_danh'] as num?)?.toInt() == 1,
      ngayTao: (json['ngay_tao'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
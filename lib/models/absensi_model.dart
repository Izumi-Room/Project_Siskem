class AbsensiModel {
  final int id;
  final int userId;
  final String docId;
  final String userUid;
  final String? nama;
  final String? nim;
  final String? email;
  final String tanggal;
  final String jam;
  final String status;
  final String cipherText;
  final String? reason; // Keterangan untuk absensi Sakit/Izin manual

  AbsensiModel({
    required this.id,
    required this.userId,
    required this.docId,
    required this.userUid,
    this.nama,
    this.nim,
    this.email,
    required this.tanggal,
    required this.jam,
    required this.status,
    required this.cipherText,
    this.reason,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    final docId = (json['doc_id'] ?? json['id'] ?? '').toString();
    final userUid = (json['user_uid'] ?? json['user_id'] ?? '').toString();
    return AbsensiModel(
      id: json['id'] is int ? json['id'] : docId.hashCode,
      userId: json['user_id'] is int ? json['user_id'] : userUid.hashCode,
      docId: docId,
      userUid: userUid,
      nama: (json['nama'] as String?) ,
      nim: (json['nim'] as String?),
      email: (json['email'] as String?),
      tanggal: (json['tanggal'] as String?) ?? '-',
      jam: (json['jam'] as String?) ?? '-',
      status: (json['status'] as String?) ?? '-',
      cipherText: (json['cipher_text'] as String?) ?? '',
      reason: (json['reason'] as String?),
    );
  }

  bool get isManual => cipherText.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'doc_id': docId,
      'user_uid': userUid,
      'nama': nama,
      'nim': nim,
      'email': email,
      'tanggal': tanggal,
      'jam': jam,
      'status': status,
      'cipher_text': cipherText,
      if (reason != null) 'reason': reason,
    };
  }
}

class AbsensiModel {
  final int id;
  final int userId;
  final String? nama; // Joined from users (Admin view)
  final String? nim; // Joined from users (Admin view)
  final String? email; // Joined from users (Admin view)
  final String tanggal;
  final String jam;
  final String status;
  final String cipherText;

  AbsensiModel({
    required this.id,
    required this.userId,
    this.nama,
    this.nim,
    this.email,
    required this.tanggal,
    required this.jam,
    required this.status,
    required this.cipherText,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      nama: json['nama'] as String?,
      nim: json['nim'] as String?,
      email: json['email'] as String?,
      tanggal: json['tanggal'] as String,
      jam: json['jam'] as String,
      status: json['status'] as String,
      cipherText: json['cipher_text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nama': nama,
      'nim': nim,
      'email': email,
      'tanggal': tanggal,
      'jam': jam,
      'status': status,
      'cipher_text': cipherText,
    };
  }
}

class UserModel {
  final int id;
  final String nama;
  final String? nim; // Nullable for admin
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.nama,
    this.nim,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: json['nama'] as String,
      nim: json['nim'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama, 'nim': nim, 'email': email, 'role': role};
  }

  bool get isAdmin => role == 'admin';
  bool get isMahasiswa => role == 'mahasiswa';
}

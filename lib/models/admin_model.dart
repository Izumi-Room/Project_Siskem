import 'user_model.dart';

class AdminModel {
  final UserModel user;
  final int totalMahasiswa;
  final int totalKehadiran;

  AdminModel({
    required this.user,
    this.totalMahasiswa = 0,
    this.totalKehadiran = 0,
  });

  factory AdminModel.fromUser(
    UserModel user, {
    int totalMahasiswa = 0,
    int totalKehadiran = 0,
  }) {
    return AdminModel(
      user: user,
      totalMahasiswa: totalMahasiswa,
      totalKehadiran: totalKehadiran,
    );
  }
}

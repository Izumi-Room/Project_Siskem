import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'realtime_database_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    RealtimeDatabaseService? databaseService,
  })  : _firebaseAuth = firebaseAuth,
        _providedDatabaseService = databaseService;

  final FirebaseAuth? _firebaseAuth;
  final RealtimeDatabaseService? _providedDatabaseService;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  RealtimeDatabaseService get _databaseService =>
      _providedDatabaseService ?? RealtimeDatabaseService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return {'status': 'error', 'message': 'Login gagal.'};
      }

      final user = await _databaseService.getUserProfile(firebaseUser.uid);
      if (user == null) {
        await _auth.signOut();
        return {
          'status': 'error',
          'message': 'Profil pengguna belum tersedia di Realtime Database.',
        };
      }

      return {'status': 'success', 'user': user.toJson()};
    } on FirebaseAuthException catch (error) {
      return {'status': 'error', 'message': _authMessage(error)};
    } catch (error) {
      return {'status': 'error', 'message': 'Login gagal: $error'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String nim,
    required String email,
    required String password,
  }) async {
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return {'status': 'error', 'message': 'Registrasi gagal.'};
      }
      createdUser = firebaseUser;

      await _databaseService.createUserProfile(
        uid: firebaseUser.uid,
        nama: nama,
        nim: nim,
        email: email,
      );
      await firebaseUser.updateDisplayName(nama);
      await _auth.signOut();

      return {'status': 'success'};
    } on FirebaseAuthException catch (error) {
      // Rollback: hapus akun auth jika profile write belum sempat dilakukan
      if (createdUser != null) {
        try { await createdUser.delete(); } catch (_) {}
      }
      return {'status': 'error', 'message': _authMessage(error)};
    } catch (error) {
      // Database write gagal → rollback akun auth
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      return {'status': 'error', 'message': 'Registrasi gagal. Coba lagi.'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'status': 'success'};
    } on FirebaseAuthException catch (error) {
      return {'status': 'error', 'message': _authMessage(error)};
    } catch (_) {
      return {'status': 'error', 'message': 'Gagal mengirim email reset.'};
    }
  }

  Future<UserModel?> getUserSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _databaseService.getUserProfile(firebaseUser.uid);
  }

  Future<bool> logout() async {
    await _auth.signOut();
    return true;
  }

  String _authMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      default:
        return error.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}

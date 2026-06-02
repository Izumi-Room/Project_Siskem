import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/absensi_model.dart';
import '../models/qr_code_model.dart';
import '../models/user_model.dart';

class RealtimeDatabaseService {
  RealtimeDatabaseService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: _databaseUrl,
            );

  static const _databaseUrl =
      String.fromEnvironment(
        'FIREBASE_DATABASE_URL',
        defaultValue: 'https://siskem-firebase-default-rtdb.firebaseio.com',
      );

  final FirebaseDatabase _database;

  DatabaseReference get _users => _database.ref('users');
  DatabaseReference get _barcodes => _database.ref('barcode');
  DatabaseReference get _absensi => _database.ref('absensi');
  DatabaseReference get _qrCodes => _database.ref('qr_codes');
  DatabaseReference get _attendance => _database.ref('attendance');

  Future<void> createUserProfile({
    required String uid,
    required String nama,
    required String nim,
    required String email,
    String role = 'mahasiswa',
  }) async {
    await _users.child(uid).set({
      'uid': uid,
      'nama': nama,
      'nim': nim,
      'email': email,
      'role': role,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final snapshot = await _users.child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return _userFromMap(uid, _snapshotMap(snapshot));
  }

  Future<List<UserModel>> getUsers({bool mahasiswaOnly = true}) async {
    final query = mahasiswaOnly
        ? _users.orderByChild('role').equalTo('mahasiswa')
        : _users.orderByKey();
    final snapshot = await query.get();
    final list = snapshot.children
        .where((child) => child.value != null)
        .map((child) => _userFromMap(child.key ?? '', _snapshotMap(child)))
        .toList();
    list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  Future<String> createBarcodeSession({
    required String adminUid,
    required int adminId,
    required String kode,
    required int durationMinutes,
  }) async {
    final now = DateTime.now();
    final expiredAt = now.add(Duration(minutes: durationMinutes));
    final ref = _barcodes.push();
    final id = ref.key ?? now.microsecondsSinceEpoch.toString();

    await ref.set({
      'id': id,
      'admin_uid': adminUid,
      'admin_id': adminId,
      'kode': kode,
      'expired_at': expiredAt.toIso8601String(),
      'expired_at_ms': expiredAt.millisecondsSinceEpoch,
      'created_at': ServerValue.timestamp,
      'duration_minutes': durationMinutes,
    });

    return id;
  }

  Future<void> saveAbsensi({
    required UserModel user,
    required String sessionId,
    required String tanggal,
    required String jam,
    required String status,
    required String cipherText,
  }) async {
    final position = await _getCurrentPositionOrNull();
    final now = DateTime.now();
    final ref = _absensi.push();
    final id = ref.key ?? now.microsecondsSinceEpoch.toString();

    await ref.set({
      'id': id,
      'user_id': user.id,
      'user_uid': user.uid,
      'session_id': sessionId,
      'nama': user.nama,
      'nim': user.nim,
      'email': user.email,
      'tanggal': tanggal,
      'jam': jam,
      'status': status,
      'cipher_text': cipherText,
      'created_at': ServerValue.timestamp,
      'created_at_text': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    });
  }

  Future<List<AbsensiModel>> getRiwayatAbsensi(String userUid) async {
    final snapshot =
        await _absensi.orderByChild('user_uid').equalTo(userUid).get();
    final list = snapshot.children
        .where((child) => child.value != null)
        .map((child) => _absensiFromMap(child.key ?? '', _snapshotMap(child)))
        .toList();
    list.sort((a, b) => b.docId.compareTo(a.docId));
    return list;
  }

  Future<List<AbsensiModel>> getAllAbsensi() async {
    final snapshot = await _absensi.orderByChild('created_at').get();
    final list = snapshot.children
        .where((child) => child.value != null)
        .map((child) => _absensiFromMap(child.key ?? '', _snapshotMap(child)))
        .toList();
    list.sort((a, b) => b.docId.compareTo(a.docId));
    return list;
  }

  Stream<List<AbsensiModel>> watchAllAbsensi() {
    return _absensi.orderByChild('created_at').onValue.map((event) {
      final list = event.snapshot.children
          .where((child) => child.value != null)
          .map((child) => _absensiFromMap(child.key ?? '', _snapshotMap(child)))
          .toList();
      list.sort((a, b) => b.docId.compareTo(a.docId));
      return list;
    });
  }

  Stream<List<AbsensiModel>> watchRiwayatAbsensi(String userUid) {
    return _absensi.orderByChild('user_uid').equalTo(userUid).onValue.map(
      (event) {
        final list = event.snapshot.children
            .where((child) => child.value != null)
            .map(
                (child) => _absensiFromMap(child.key ?? '', _snapshotMap(child)))
            .toList();
        list.sort((a, b) => b.docId.compareTo(a.docId));
        return list;
      },
    );
  }

  Future<Map<String, int>> getUserStats(String userUid) async {
    final list = await getRiwayatAbsensi(userUid);
    return _countStatuses(list);
  }

  Future<Map<String, int>> getAdminStats() async {
    final users = await getUsers();
    final absensi = await getAllAbsensi();
    return {
      'mahasiswa': users.length,
      'absensi': absensi.length,
    };
  }

  // ── QR Code Management (qr_codes node) ─────────────────────────────────

  /// Buat QR Code baru di node `qr_codes/{qrId}`.
  /// Mengembalikan qrId yang dihasilkan.
  Future<String> createQrCode({
    required String adminUid,
    required String location,
    required String status,
    required int durationMinutes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredAt = now + (durationMinutes * 60 * 1000);
    final ref = _qrCodes.push();
    final qrId = ref.key!;

    await ref.set({
      'location': location,
      'createdAt': ServerValue.timestamp,
      'expiredAt': expiredAt,
      'active': true,
      'status': status,
      'adminUid': adminUid,
    });

    return qrId;
  }

  /// Ambil data QR Code berdasarkan qrId.
  /// Mengembalikan null jika tidak ditemukan.
  Future<QrCodeModel?> getQrCode(String qrId) async {
    final snapshot = await _qrCodes.child(qrId).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return QrCodeModel.fromJson(qrId, _snapshotMap(snapshot));
  }

  /// Nonaktifkan QR Code (set active = false).
  Future<void> deactivateQrCode(String qrId) async {
    await _qrCodes.child(qrId).update({'active': false});
  }

  // ── Attendance (attendance node) ─────────────────────────────────────────

  /// Cek apakah user sudah absen hari ini.
  /// Path: `attendance/{uid}/{tanggal}`
  Future<bool> hasAttendanceToday(String uid, String tanggal) async {
    final snapshot = await _attendance.child(uid).child(tanggal).get();
    return snapshot.exists && snapshot.value != null;
  }

  /// Simpan absensi manual (Sakit/Izin) tanpa QR Code.
  /// Digunakan ketika mahasiswa tidak bisa hadir dan ingin submit keterangan.
  Future<void> submitManualAttendance({
    required UserModel user,
    required String status, // "Sakit" atau "Izin"
    required String tanggal,
    required String reason, // Alasan/keterangan
  }) async {
    final position = await _getCurrentPositionOrNull();
    final now = DateTime.now();

    // Tulis ke node attendance/{uid}/{tanggal} — hanya bisa 1x (Security Rules)
    await _attendance.child(user.uid).child(tanggal).set({
      'checkInTime': ServerValue.timestamp,
      'location': 'Manual Submission',
      'qrId': 'manual_$status',
      'status': status,
      'nama': user.nama,
      'nim': user.nim,
      'email': user.email,
      'reason': reason,
      'submissionType': 'manual',
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    });

    // Juga tulis ke node absensi (legacy, untuk kompatibilitas tampilan riwayat)
    final jam = DateFormat('HH:mm').format(now);
    final ref = _absensi.push();
    await ref.set({
      'id': ref.key,
      'user_id': user.id,
      'user_uid': user.uid,
      'session_id': 'manual_$status',
      'nama': user.nama,
      'nim': user.nim,
      'email': user.email,
      'tanggal': tanggal,
      'jam': jam,
      'status': status,
      'reason': reason,
      'cipher_text': '',
      'submissionType': 'manual',
      'created_at': ServerValue.timestamp,
      'created_at_text': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    });
  }

  /// Simpan absensi ke node `attendance/{uid}/{tanggal}` (struktur baru, aman).
  /// Firebase Security Rules memastikan path ini hanya bisa ditulis 1x.
  Future<void> saveAttendanceSecure({
    required UserModel user,
    required String qrId,
    required String location,
    required String status,
    required String tanggal,
    required String cipherText,
  }) async {
    final position = await _getCurrentPositionOrNull();

    // Tulis ke node attendance/{uid}/{tanggal} — hanya bisa 1x (Security Rules)
    await _attendance.child(user.uid).child(tanggal).set({
      'checkInTime': ServerValue.timestamp,
      'location': location,
      'qrId': qrId,
      'status': status,
      'nama': user.nama,
      'nim': user.nim,
      'email': user.email,
      'cipher_text': cipherText,
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    });

    // Juga tulis ke node absensi (legacy, untuk kompatibilitas tampilan riwayat)
    final now = DateTime.now();
    final jam = DateFormat('HH:mm').format(now);
    final ref = _absensi.push();
    await ref.set({
      'id': ref.key,
      'user_id': user.id,
      'user_uid': user.uid,
      'session_id': qrId,
      'nama': user.nama,
      'nim': user.nim,
      'email': user.email,
      'tanggal': tanggal,
      'jam': jam,
      'status': status,
      'cipher_text': cipherText,
      'created_at': ServerValue.timestamp,
      'created_at_text': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    });
  }

  /// Ambil data absensi hari ini dari node `attendance/{uid}/{tanggal}`.
  Future<Map<String, dynamic>?> getAttendanceToday(
      String uid, String tanggal) async {
    final snapshot = await _attendance.child(uid).child(tanggal).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return _snapshotMap(snapshot);
  }

  // ── Validasi QR 5 Langkah (Server-side) ─────────────────────────────────

  /// Validasi lengkap QR Code sebelum menyimpan absensi.
  ///
  /// Mengembalikan map dengan:
  /// - `valid`: bool
  /// - `message`: String (pesan error atau sukses)
  /// - `qrData`: QrCodeModel? (jika valid)
  Future<Map<String, dynamic>> validateAndSubmitAttendance({
    required UserModel user,
    required String qrId,
    required String cipherText,
    required String tanggal,
  }) async {
    // ── Langkah 1: Cek QR ada di database ──────────────────────────────
    final qrData = await getQrCode(qrId);
    if (qrData == null) {
      return {
        'valid': false,
        'message': 'QR tidak valid. Kode tidak ditemukan di database.',
      };
    }

    // ── Langkah 2: Cek status active ───────────────────────────────────
    if (!qrData.active) {
      return {
        'valid': false,
        'message': 'QR sudah tidak aktif. Minta Admin membuat sesi baru.',
      };
    }

    // ── Langkah 3: Cek masa berlaku (expiredAt) ─────────────────────────
    if (qrData.isExpired) {
      return {
        'valid': false,
        'message':
            'QR Code sudah kedaluwarsa. Sesi absensi telah berakhir.',
      };
    }

    // ── Langkah 4: Cek absensi hari ini (1x per hari) ──────────────────
    final alreadyAbsen = await hasAttendanceToday(user.uid, tanggal);
    if (alreadyAbsen) {
      return {
        'valid': false,
        'message':
            'Anda sudah melakukan absensi hari ini. Tidak dapat absen dua kali.',
      };
    }

    // ── Langkah 5: Semua valid → simpan absensi ─────────────────────────
    try {
      await saveAttendanceSecure(
        user: user,
        qrId: qrId,
        location: qrData.location,
        status: qrData.status,
        tanggal: tanggal,
        cipherText: cipherText,
      );

      return {
        'valid': true,
        'message': 'Absensi berhasil dicatat.',
        'qrData': qrData,
      };
    } on Exception catch (e) {
      // Tangkap error permission denied dari Security Rules (absen duplikat)
      final msg = e.toString();
      if (msg.contains('permission-denied') ||
          msg.contains('Permission denied')) {
        return {
          'valid': false,
          'message':
              'Anda sudah melakukan absensi hari ini (ditolak oleh server).',
        };
      }
      rethrow;
    }
  }

  // ── Ambil semua attendance (admin view) ──────────────────────────────────

  Future<List<AbsensiModel>> getAllAttendance() async {
    final snapshot = await _attendance.get();
    final list = <AbsensiModel>[];
    if (!snapshot.exists) return list;

    for (final uidSnap in snapshot.children) {
      final uid = uidSnap.key ?? '';
      for (final dateSnap in uidSnap.children) {
        if (dateSnap.value == null) continue;
        final data = _snapshotMap(dateSnap);
        list.add(_absensiFromAttendanceMap(uid, dateSnap.key ?? '', data));
      }
    }

    list.sort((a, b) => b.docId.compareTo(a.docId));
    return list;
  }

  AbsensiModel _absensiFromAttendanceMap(
      String uid, String tanggal, Map<String, dynamic> data) {
    return AbsensiModel.fromJson({
      'doc_id': '$uid/$tanggal',
      'id': '$uid/$tanggal'.hashCode,
      'user_uid': uid,
      'user_id': uid.hashCode,
      'nama': data['nama'] ?? '-',
      'nim': data['nim'] ?? '-',
      'email': data['email'] ?? '-',
      'tanggal': tanggal,
      'jam': _msToJam(data['checkInTime']),
      'status': data['status'] ?? '-',
      'cipher_text': data['cipher_text'] ?? '',
      if (data['reason'] != null) 'reason': data['reason'],
    });
  }

  String _msToJam(dynamic ms) {
    try {
      final millis = ms is int ? ms : int.parse(ms.toString());
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  UserModel _userFromMap(String key, Map<String, dynamic> data) {
    return UserModel.fromJson({
      ...data,
      'uid': data['uid'] ?? key,
      'id': data['id'] ?? key.hashCode,
      'nama': data['nama'] ?? '-',
      'email': data['email'] ?? '-',
      'role': data['role'] ?? 'mahasiswa',
    });
  }

  AbsensiModel _absensiFromMap(String key, Map<String, dynamic> data) {
    final userUid = (data['user_uid'] ?? data['user_id'] ?? '').toString();
    return AbsensiModel.fromJson({
      ...data,
      'doc_id': key,
      'id': data['id'] ?? key.hashCode,
      'user_id': data['user_id'] is int ? data['user_id'] : userUid.hashCode,
      'user_uid': userUid,
      'tanggal': data['tanggal'] ?? '-',
      'jam': data['jam'] ?? '-',
      'status': data['status'] ?? '-',
      'cipher_text': data['cipher_text'] ?? '',
      if (data['reason'] != null) 'reason': data['reason'],
    });
  }

  Map<String, dynamic> _snapshotMap(DataSnapshot snapshot) {
    return _toStringKeyMap(snapshot.value);
  }

  Map<String, dynamic> _toStringKeyMap(Object? value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  Map<String, int> _countStatuses(List<AbsensiModel> list) {
    var hadir = 0;
    var sakit = 0;
    var izin = 0;

    for (final item in list) {
      final status = item.status.toLowerCase();
      if (status.contains('hadir')) hadir++;
      if (status.contains('sakit')) sakit++;
      if (status.contains('izin')) izin++;
    }

    return {'hadir': hadir, 'sakit': sakit, 'izin': izin};
  }

  Future<Position?> _getCurrentPositionOrNull() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

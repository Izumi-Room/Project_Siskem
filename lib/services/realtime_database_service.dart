import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/absensi_model.dart';
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

/// Model untuk node `qr_codes/{qrId}` di Firebase Realtime Database.
///
/// Struktur Firebase:
/// ```json
/// {
///   "qr_codes": {
///     "QR_abc123": {
///       "location": "Kantor Pusat",
///       "createdAt": 1751234567890,
///       "expiredAt": 1751238167890,
///       "active": true,
///       "status": "Hadir",
///       "adminUid": "uid_admin"
///     }
///   }
/// }
/// ```
class QrCodeModel {
  final String qrId;
  final String location;
  final int createdAt;
  final int expiredAt;
  final bool active;
  final String status;
  final String adminUid;

  const QrCodeModel({
    required this.qrId,
    required this.location,
    required this.createdAt,
    required this.expiredAt,
    required this.active,
    required this.status,
    required this.adminUid,
  });

  factory QrCodeModel.fromJson(String id, Map<String, dynamic> json) {
    return QrCodeModel(
      qrId: id,
      location: (json['location'] ?? '').toString(),
      createdAt: _parseInt(json['createdAt']),
      expiredAt: _parseInt(json['expiredAt']),
      active: json['active'] == true,
      status: (json['status'] ?? 'Hadir').toString(),
      adminUid: (json['adminUid'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location,
        'createdAt': createdAt,
        'expiredAt': expiredAt,
        'active': active,
        'status': status,
        'adminUid': adminUid,
      };

  /// QR sudah melewati waktu expiredAt
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiredAt;

  /// QR valid: aktif dan belum expired
  bool get isValid => active && !isExpired;

  /// Sisa waktu berlaku dalam detik (0 jika sudah expired)
  int get remainingSeconds {
    final remaining =
        expiredAt - DateTime.now().millisecondsSinceEpoch;
    return remaining > 0 ? (remaining / 1000).floor() : 0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

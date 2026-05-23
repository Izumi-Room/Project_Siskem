class BarcodeModel {
  final int id;
  final String kode; // Triple DES Cipher text
  final String expiredAt;

  BarcodeModel({required this.id, required this.kode, required this.expiredAt});

  factory BarcodeModel.fromJson(Map<String, dynamic> json) {
    return BarcodeModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      kode: json['kode'] as String,
      expiredAt: json['expired_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'kode': kode, 'expired_at': expiredAt};
  }

  bool get isExpired {
    try {
      final expiry = DateTime.parse(expiredAt);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }
}

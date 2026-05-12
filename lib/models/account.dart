class Account {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String kycStatus;
  final String? rejectReason;
  final String? ktpUrl;
  final String? selfieUrl;
  final String? profileUrl; // [BARU] Untuk Foto Profil Custom

  Account({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    this.kycStatus = 'UNVERIFIED',
    this.rejectReason,
    this.ktpUrl,
    this.selfieUrl,
    this.profileUrl,
  });

  bool get isVerified => kycStatus == 'VERIFIED';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'kycStatus': kycStatus,
      'rejectReason': rejectReason,
      'ktpUrl': ktpUrl,
      'selfieUrl': selfieUrl,
      'profileUrl': profileUrl, // [BARU]
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    String status = 'UNVERIFIED';
    if (json['kycStatus'] != null) {
      status = json['kycStatus'];
    } else if (json['isVerified'] == true) {
      status = 'VERIFIED';
    }

    return Account(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] ?? '',
      kycStatus: status,
      rejectReason: json['rejectReason'],
      ktpUrl: json['ktpUrl'],
      selfieUrl: json['selfieUrl'],
      profileUrl: json['profileUrl'], // [BARU]
    );
  }
}

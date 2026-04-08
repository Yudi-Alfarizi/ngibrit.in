class Account {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber; // [BARU]
  final bool isVerified;
  final String? ktpUrl;
  final String? selfieUrl;

  Account({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber = '', // Default empty
    this.isVerified = false,
    this.ktpUrl,
    this.selfieUrl,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber, // Save ke DB
      'isVerified': isVerified,
      'ktpUrl': ktpUrl,
      'selfieUrl': selfieUrl,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] ?? '', // Load dari DB
      isVerified: json['isVerified'] ?? false,
      ktpUrl: json['ktpUrl'],
      selfieUrl: json['selfieUrl'],
    );
  }
}
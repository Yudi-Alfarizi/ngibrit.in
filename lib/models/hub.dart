class Hub {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;

  Hub({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Hub.fromJson(Map<String, dynamic> json, String docId) {
    return Hub(
      id: docId,
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
    );
  }
}

class Bike {
  final String id;
  final String name;
  final String category;
  final String image;
  final String about;
  final String level;
  final num price;
  final num rating;
  final String release;
  // [BARU] Data Lokasi Hub
  final String hubId; 
  final double hubLat;
  final double hubLng; 

  Bike({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.about,
    required this.level,
    required this.price,
    required this.rating,
    required this.release,
    this.hubId = '',
    this.hubLat = 0.0,
    this.hubLng = 0.0,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      about: json['about'] as String,
      level: json['level'] as String,
      price: json['price'] as num,
      rating: json['rating'] as num,
      release: json['release'] as String,
      // Pastikan data ini ada di Firestore collection 'Bikes'
      hubId: json['hub_id'] ?? '', 
      hubLat: (json['hub_lat'] ?? 0).toDouble(),
      hubLng: (json['hub_lng'] ?? 0).toDouble(),
    );
  }

  static Bike get empty => Bike(
    id: '', name: '', category: '', image: '', about: '', 
    level: '', price: 0, rating: 0, release: '',
  );
}
class Bike {
  final String about;
  final String category;
  final String id;
  final String image;
  final String level;
  final String name;
  final num price;
  final num rating;
  final String release;
  Bike({
    required this.about,
    required this.category,
    required this.id,
    required this.image,
    required this.level,
    required this.name,
    required this.price,
    required this.rating,
    required this.release,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      about: json['about'] as String,
      category: json['category'] as String,
      id: json['id'] as String,
      image: json['image'] as String,
      level: json['level'] as String,
      name: json['name'] as String,
      price: json['price'] as num,
      rating: json['rating'] as num,
      release: json['release'] as String,
    );
  }

  static Bike get empty => Bike (
    about: '',
    category: '',
    id: '',
    image: '',
    level: '',
    name: '',
    price: 0,
    rating: 0,
    release: '',
  );

}

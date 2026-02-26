import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id; // Firestore document ID
  final String name;
  final String category;
  final String imageUrl;
  final double rating;
  final String? location;
  final double price; // Minimum price for two
  final int deliveryTime; // in minutes 🔹 new field

  Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
    this.location,
    required this.price,
    this.deliveryTime = 30, // default 30 min
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      location: data['location']?.toString(),
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      deliveryTime: (data['estimatedDelivery'] is int)
          ? data['estimatedDelivery'] as int
          : 30, // default fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'location': location,
      'price': price,
      'deliveryTime': deliveryTime, // 🔹 include in JSON
    };
  }
}

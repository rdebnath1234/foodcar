import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final double rating;
  final bool isAvailable;
  final String cuisine;
  final String category;
  final String restaurantName;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItem({
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.price,
    required this.rating,
    required this.isAvailable,
    required this.cuisine,
    required this.category,
    required this.restaurantName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// From Firestore
  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FoodItem(
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      isAvailable: data['isAvailable'] ?? true,
      cuisine: data['cuisine'] ?? '',
      category: data['category'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt']))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt']))
          : DateTime.now(),
    );
  }

  /// From JSON (for asset import)
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      isAvailable: json['isAvailable'] ?? true,
      cuisine: json['cuisine'] ?? '',
      category: json['category'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// To JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'price': price,
      'rating': rating,
      'isAvailable': isAvailable,
      'cuisine': cuisine,
      'category': category,
      'restaurantName': restaurantName,
      'createdAt': createdAt, // Firestore converts DateTime to Timestamp automatically
      'updatedAt': updatedAt,
    };
  }
}

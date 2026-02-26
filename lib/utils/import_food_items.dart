import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item_model.dart';

/// Import food items from JSON into Firestore.
Future<void> importFoodItemsOnce(BuildContext context) async {
  try {
    final collectionRef = FirebaseFirestore.instance.collection('foodItems');

    // Load JSON data from assets
    final String jsonString =
        await rootBundle.loadString('assets/data/foodItems.json');
    final List<dynamic> jsonList = json.decode(jsonString);

    final foodItems = jsonList
        .map((json) => FoodItem.fromJson(json as Map<String, dynamic>))
        .toList();

    // Get existing food items from Firestore
    final existingSnapshot = await collectionRef.get();
    final existingKeys = existingSnapshot.docs.map((doc) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final restaurant = (data['restaurantName'] ?? '').toString().toLowerCase();
      return "${name}_$restaurant";
    }).toSet();

    // Filter only new items to import
    final newFoodItems = foodItems.where((item) {
      final key =
          "${item.name.toLowerCase()}_${item.restaurantName.toLowerCase()}";
      return !existingKeys.contains(key);
    }).toList();

    if (newFoodItems.isEmpty) {
      debugPrint('No new food items to import.');
      return;
    }

    // Import in chunks (max 500 writes per batch)
    for (var i = 0; i < newFoodItems.length; i += 500) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = newFoodItems.skip(i).take(500);

      for (var foodItem in chunk) {
        final docRef = collectionRef.doc(); // Auto ID
        batch.set(docRef, foodItem.toJson());
      }

      await batch.commit();
    }

    debugPrint('Imported ${newFoodItems.length} new food items successfully.');
  } catch (e) {
    debugPrint('Error importing food items: $e');
  }
}

// utils/import_restaurants.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../utils/restaurant_manager.dart';
import 'package:provider/provider.dart';

bool _restaurantsImported = false;

Future<void> importRestaurantsOnce(BuildContext context) async {
  if (_restaurantsImported) return; // Only import once
  _restaurantsImported = true;

  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('restaurants').get();

    final restaurants = snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc))
        .toList();

    if (restaurants.isNotEmpty) {
      final restaurantManager =
          Provider.of<RestaurantManager>(context, listen: false);
      restaurantManager.addRestaurants(restaurants);
    }

    debugPrint('Imported ${restaurants.length} restaurants successfully.');
  } catch (e) {
    debugPrint('Error importing restaurants: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import restaurants: $e')),
      );
    }
  }
}

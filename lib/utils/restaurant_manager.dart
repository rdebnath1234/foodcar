// utils/restaurant_manager.dart
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';

class RestaurantManager extends ChangeNotifier {
  final List<Restaurant> _restaurants = [];

  List<Restaurant> get restaurants => List.unmodifiable(_restaurants);

  /// Add restaurants (without duplicates based on name+category)
  void addRestaurants(List<Restaurant> newRestaurants) {
    for (var r in newRestaurants) {
      final exists = _restaurants.any((e) =>
          e.name.toLowerCase() == r.name.toLowerCase() &&
          e.category.toLowerCase() == r.category.toLowerCase());
      if (!exists) _restaurants.add(r);
    }
    notifyListeners();
  }

  void clear() {
    _restaurants.clear();
    notifyListeners();
  }
}

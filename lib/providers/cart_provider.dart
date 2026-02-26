import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, int> _cart = {};
  final Map<String, double> _prices = {};
  final Map<String, String> _images = {};

  Map<String, int> get cart => Map.unmodifiable(_cart);
  Map<String, double> get prices => Map.unmodifiable(_prices);
  Map<String, String> get images => Map.unmodifiable(_images);

  int get totalItems => _cart.values.fold(0, (sum, qty) => sum + qty);

  double get totalPrice => _cart.entries.fold(
        0.0,
        (sum, entry) => sum + (entry.value * (_prices[entry.key] ?? 0)),
      );

  void addItem(String name, double price, {String imageUrl = ''}) {
    if (_cart.containsKey(name)) {
      _cart[name] = _cart[name]! + 1;
    } else {
      _cart[name] = 1;
      _prices[name] = price;
      _images[name] = imageUrl;
    }
    notifyListeners();
  }

  void removeItem(String name) {
    if (!_cart.containsKey(name)) return;

    if (_cart[name]! > 1) {
      _cart[name] = _cart[name]! - 1;
    } else {
      removeItemCompletely(name);
      return;
    }
    notifyListeners();
  }

  void removeItemCompletely(String name) {
    _cart.remove(name);
    _prices.remove(name);
    _images.remove(name);
    notifyListeners();
  }

  int getQuantity(String name) => _cart[name] ?? 0;

  void clearCart() {
    _cart.clear();
    _prices.clear();
    _images.clear();
    notifyListeners();
  }
}

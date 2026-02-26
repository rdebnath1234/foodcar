// utils/cart_manager.dart
import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });
}

class CartManager extends ChangeNotifier {
  // Singleton
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final Map<String, CartItem> _items = {};

  /// Get total items in cart
  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Get total price
  double get totalPrice =>
      _items.values.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  /// Add an item to the cart
  void addItem(String name, double price, {String? imageUrl}) {
    if (_items.containsKey(name)) {
      _items[name]!.quantity += 1;
    } else {
      _items[name] = CartItem(name: name, price: price, imageUrl: imageUrl);
    }
    notifyListeners();
  }

  /// Remove a single quantity of an item
  void removeItem(String name) {
    if (!_items.containsKey(name)) return;
    final item = _items[name]!;
    item.quantity -= 1;
    if (item.quantity <= 0) {
      _items.remove(name);
    }
    notifyListeners();
  }

  /// Remove an item completely from the cart
  void removeItemCompletely(String name) {
    if (_items.containsKey(name)) {
      _items.remove(name);
      notifyListeners();
    }
  }

  /// Get quantity of a specific item
  int getQuantity(String name) => _items[name]?.quantity ?? 0;

  /// Get image URL of a specific item
  String getImageUrl(String name) => _items[name]?.imageUrl ?? '';

  /// Clear the cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Get a list of all items
  List<CartItem> get items => _items.values.toList();
}

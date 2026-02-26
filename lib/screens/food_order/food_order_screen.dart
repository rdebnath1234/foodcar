// lib/screens/food_order/food_order_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant_model.dart';
import '../../models/food_item_model.dart';
import '../../utils/cart_manager.dart';
import 'food_menu_sheet.dart';
import '../../screens/check_out.dart';
import '../../screens/food_order/restaurant_scroller.dart';

class FoodOrderScreen extends StatefulWidget {
  final String searchQuery;
  const FoodOrderScreen({super.key, required this.searchQuery});

  @override
  State<FoodOrderScreen> createState() => _FoodOrderScreenState();
}

class _FoodOrderScreenState extends State<FoodOrderScreen> {
  List<Restaurant> recommendedRestaurants = [];
  List<Restaurant> popularRestaurants = [];
  bool isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  @override
  void didUpdateWidget(covariant FoodOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), fetchRestaurants);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchRestaurants() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('category', whereIn: ['recommended', 'popular'])
          .get();

      final uniqueRestaurants = <String, Restaurant>{};
      for (var doc in snapshot.docs) {
        final restaurant = Restaurant.fromFirestore(doc);
        uniqueRestaurants.putIfAbsent(restaurant.name, () => restaurant);
      }

      final allRestaurants = uniqueRestaurants.values.toList();
      final query = widget.searchQuery.toLowerCase();

      setState(() {
        recommendedRestaurants = allRestaurants
            .where((r) =>
                r.category.toLowerCase() == 'recommended' &&
                r.name.toLowerCase().contains(query))
            .toList();

        popularRestaurants = allRestaurants
            .where((r) =>
                r.category.toLowerCase() == 'popular' &&
                r.name.toLowerCase().contains(query))
            .toList();

        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load restaurants: $e')));
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAndShowMenu(Restaurant restaurant) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('foodItems')
          .where('restaurantName', isEqualTo: restaurant.name)
          .get();

      final foodItems =
          snapshot.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

      if (foodItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No menu found for ${restaurant.name}')));
        }
        return;
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView.builder(
              controller: controller,
              itemCount: foodItems.length,
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: FoodMenuSheet(
                  food: foodItems[index],
                  onAdd: () {
                    setState(() {}); // refresh bottom bar
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading menu: $e')));
      }
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    final cartManager = context.watch<CartManager>();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recommendedRestaurants.isNotEmpty) ...[
                          _buildSectionTitle('Recommended for you'),
                          const SizedBox(height: 8),
                          RestaurantScroller(
                              restaurants: recommendedRestaurants,
                              onViewMenu: _fetchAndShowMenu),
                        ],
                        if (popularRestaurants.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle('Popular Restaurants'),
                          const SizedBox(height: 8),
                          RestaurantScroller(
                              restaurants: popularRestaurants,
                              onViewMenu: _fetchAndShowMenu),
                        ],
                        if (recommendedRestaurants.isEmpty &&
                            popularRestaurants.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                'No restaurants found.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cartManager.totalItems > 0
          ? SafeArea(
              child: Container(
                height: 65,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${cartManager.totalItems} item${cartManager.totalItems > 1 ? 's' : ''} | Subtotal: \$${cartManager.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('View Cart'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcar/screens/dinning/restaurent_tile.dart';
import '../../../models/restaurant_model.dart';
import 'restaurant_details.dart';

class Dining extends StatefulWidget {
  final String searchQuery;
  const Dining({super.key, required this.searchQuery});

  @override
  State<Dining> createState() => _DiningState();
}

class _DiningState extends State<Dining> {
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool isLoading = true;

  String? userId;
  Set<String> _favoriteIds = {};
  StreamSubscription<QuerySnapshot>? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      _listenToFavorites(); // listen in real-time
      await _fetchRestaurants();
    }
  }

  void _listenToFavorites() {
    if (userId == null) return;

    _favoritesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      final ids = snapshot.docs.map((doc) => doc.id).toSet();
      setState(() {
        _favoriteIds = ids;
      });
    });
  }

  Future<void> _toggleFavorite(Restaurant restaurant) async {
    if (userId == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(restaurant.id);

    final isFav = _favoriteIds.contains(restaurant.id);

    // Optimistic UI update
    setState(() {
      if (isFav) {
        _favoriteIds.remove(restaurant.id);
      } else {
        _favoriteIds.add(restaurant.id);
      }
    });

    // Firestore update
    try {
      if (isFav) {
        await favRef.delete();
      } else {
        await favRef.set({
          'name': restaurant.name,
          'imageUrl': restaurant.imageUrl,
          'location': restaurant.location,
          'rating': restaurant.rating,
          'category': restaurant.category,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // rollback if Firestore fails
      setState(() {
        if (isFav) {
          _favoriteIds.add(restaurant.id);
        } else {
          _favoriteIds.remove(restaurant.id);
        }
      });
      debugPrint("Failed to update favorite: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update favorite")),
        );
      }
    }
  }

  Future<void> _fetchRestaurants() async {
    setState(() => isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('restaurants').get();

      _allRestaurants =
          snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();

      _filterRestaurants();
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load restaurants: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterRestaurants() {
    final query = widget.searchQuery.toLowerCase();
    setState(() {
      _filteredRestaurants = _allRestaurants
          .where((r) =>
              (r.category.toLowerCase() == 'recommended' ||
                  r.category.toLowerCase() == 'popular') &&
              r.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredRestaurants.isEmpty) {
      return const Center(child: Text('Restaurant not found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _filteredRestaurants[index];
        final isFavorite = _favoriteIds.contains(restaurant.id);

        return RestaurantTile(
          key: ValueKey(restaurant.id), // ensures proper rebuild
          restaurant: restaurant,
          isFavorite: isFavorite,
          onTapFavorite: () => _toggleFavorite(restaurant),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RestaurantDetailsPage(restaurant: restaurant),
              ),
            );
          },
        );
      },
    );
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/restaurant_model.dart';
import 'dinning/restaurant_details.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? userId;
  Set<String> _favoriteIds = {};
  List<Restaurant> _favoriteRestaurants = [];
  bool isLoading = true;

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
      _listenToFavorites();
      await _fetchFavoriteRestaurants();
    }
  }

  void _listenToFavorites() {
    if (userId == null) return;

    _favoritesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) async {
      final ids = snapshot.docs.map((doc) => doc.id).toSet();
      setState(() {
        _favoriteIds = ids;
      });
      await _fetchFavoriteRestaurants();
    });
  }

  Future<void> _fetchFavoriteRestaurants() async {
    if (_favoriteIds.isEmpty) {
      setState(() {
        _favoriteRestaurants = [];
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where(FieldPath.documentId, whereIn: _favoriteIds.toList())
          .get();

      _favoriteRestaurants =
          snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load favorites: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
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
        _favoriteRestaurants.removeWhere((r) => r.id == restaurant.id);
      } else {
        _favoriteIds.add(restaurant.id);
        _favoriteRestaurants.add(restaurant);
      }
    });

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
      debugPrint("Failed to update favorite: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update favorite")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (_favoriteRestaurants.isEmpty) {
      return const Center(child: Text('No favorite restaurants yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _favoriteRestaurants[index];
        return RestaurantTile(
          restaurant: restaurant,
          isFavorite: true,
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

// Reuse the same RestaurantTile widget from Dining screen
class RestaurantTile extends StatefulWidget {
  final Restaurant restaurant;
  final bool isFavorite;
  final VoidCallback onTapFavorite;
  final VoidCallback onTap;

  const RestaurantTile({
    super.key,
    required this.restaurant,
    required this.isFavorite,
    required this.onTapFavorite,
    required this.onTap,
  });

  @override
  State<RestaurantTile> createState() => _RestaurantTileState();
}

class _RestaurantTileState extends State<RestaurantTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _toggleFavorite() {
    _controller.forward(from: 0);
    widget.onTapFavorite();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.restaurant.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(height: 200, color: Colors.grey[300]),
                    errorWidget: (context, url, error) =>
                        Container(height: 200, color: Colors.grey[300]),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: ScaleTransition(
                      scale: _animation,
                      child: CircleAvatar(
                        backgroundColor: Colors.white70,
                        child: Icon(
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isFavorite ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.restaurant.name,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(widget.restaurant.location ?? '',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStarRating(widget.restaurant.rating),
                const SizedBox(width: 8),
                Text('${widget.restaurant.rating.toStringAsFixed(1)} stars',
                    style: TextStyle(color: Colors.grey[800])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++)
          const Icon(Icons.star, color: Colors.amber, size: 16),
        if (hasHalfStar)
          const Icon(Icons.star_half, color: Colors.amber, size: 16),
        for (int i = 0; i < emptyStars; i++)
          const Icon(Icons.star_border, color: Colors.amber, size: 16),
      ],
    );
  }
}

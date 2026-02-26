import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';
import 'image_widgets.dart';
import '/widgets/bouncing_gradient_discount_badge.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final Function(Restaurant) onViewMenu;

  const RestaurantCard({super.key, required this.restaurant, required this.onViewMenu});

  Widget _buildStarRating(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    List<Widget> stars = [];
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 14));
    }
    if (hasHalfStar) stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 14));
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 14));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final discountText = "20% OFF";

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb ||
                        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                    ? HoverableRestaurantImage(
                        imageUrl: restaurant.imageUrl,
                        onViewMenu: () => onViewMenu(restaurant),
                      )
                    : TapableRestaurantImage(
                        imageUrl: restaurant.imageUrl,
                        onViewMenu: () => onViewMenu(restaurant),
                      ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: BouncingGradientDiscountBadge(text: discountText),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: _buildStarRating(restaurant.rating),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            restaurant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          if (restaurant.location != null)
            Text(
              restaurant.location!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }
}

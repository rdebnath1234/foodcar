import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../models/restaurant_model.dart';
import 'hoverable_restaurant_image.dart';
import 'tapable_restaurant_image.dart';
import 'bouncing_gradient_discount_badge.dart';
import 'star_rating.dart';

class RestaurantScroller extends StatelessWidget {
  final List<Restaurant> restaurants;
  final Function(Restaurant) onViewMenu;

  const RestaurantScroller({
    super.key,
    required this.restaurants,
    required this.onViewMenu,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          const discountText = "20% OFF";

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
                              (Platform.isMacOS ||
                                  Platform.isWindows ||
                                  Platform.isLinux)
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
                      child: const BouncingGradientDiscountBadge(text: discountText),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: StarRating(rating: restaurant.rating),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.location ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Min for two: \$${restaurant.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

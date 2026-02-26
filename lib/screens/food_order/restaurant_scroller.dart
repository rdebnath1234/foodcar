import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';
import 'restaurant_card.dart';

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
          return RestaurantCard(
            restaurant: restaurants[index],
            onViewMenu: onViewMenu,
          );
        },
      ),
    );
  }
}

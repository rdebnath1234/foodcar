import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TapableRestaurantImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onViewMenu;
  const TapableRestaurantImage({super.key, required this.imageUrl, required this.onViewMenu});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onViewMenu,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: double.infinity,
          height: 160,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          width: double.infinity,
          height: 160,
          color: Colors.grey[300],
          child: const Icon(Icons.fastfood, size: 50, color: Colors.white),
        ),
      ),
    );
  }
}

class HoverableRestaurantImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onViewMenu;
  const HoverableRestaurantImage({super.key, required this.imageUrl, required this.onViewMenu});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TapableRestaurantImage(imageUrl: imageUrl, onViewMenu: onViewMenu),
    );
  }
}

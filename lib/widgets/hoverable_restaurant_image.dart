import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'animated_view_menu_button.dart';

class HoverableRestaurantImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onViewMenu;
  const HoverableRestaurantImage({
    super.key,
    required this.imageUrl,
    required this.onViewMenu,
  });

  @override
  State<HoverableRestaurantImage> createState() =>
      _HoverableRestaurantImageState();
}

class _HoverableRestaurantImageState extends State<HoverableRestaurantImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: widget.imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 180,
              color: Colors.grey[300],
              child: const Icon(Icons.storefront, size: 50, color: Colors.grey),
            ),
          ),
          AnimatedOpacity(
            opacity: _isHovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedViewMenuButton(
              onPressed: widget.onViewMenu,
              text: 'View Menu',
            ),
          ),
        ],
      ),
    );
  }
}

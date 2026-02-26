// lib/screens/food_order/food_menu_sheet.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../models/food_item_model.dart';
import '../../utils/cart_manager.dart';

class FoodMenuSheet extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onAdd;

  const FoodMenuSheet({super.key, required this.food, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cartManager = context.watch<CartManager>();
    final quantity = cartManager.getQuantity(food.name);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Food image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: food.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text("\$${food.price.toStringAsFixed(2)}"),
                ],
              ),
            ),
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: quantity > 0
                        ? () {
                            cartManager.removeItem(food.name);
                            if (onAdd != null) onAdd!();
                          }
                        : null,
                  ),
                  Text(
                    "$quantity",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      cartManager.addItem(food.name, food.price,
                          imageUrl: food.imageUrl);
                      if (onAdd != null) onAdd!();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:foodcar/utils/cart_manager.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartManager>();
    final formatter = NumberFormat.currency(symbol: '\$');

    double gst = cart.totalPrice * 0.05;
    double deliveryFee = cart.totalItems > 0 ? 3.0 : 0.0;
    double grandTotal = cart.totalPrice + gst + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.totalItems == 0
                ? const Center(
                    child: Text(
                      "Your cart is empty 🛒",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final name = item.name;
                      final qty = item.quantity;
                      final price = item.price;
                      final imageUrl = item.imageUrl;

                      return Dismissible(
                        key: Key(name),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => cart.removeItemCompletely(name),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Food image
                                if (imageUrl != null && imageUrl.isNotEmpty)
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                                child:
                                                    CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.fastfood, color: Colors.white),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[300],
                                    ),
                                    child: const Icon(Icons.fastfood, color: Colors.white),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text("${formatter.format(price)} each"),
                                      Text("Total: ${formatter.format(price * qty)}",
                                          style: const TextStyle(
                                              color: Colors.black54, fontSize: 13)),
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
                                        onPressed: () => cart.removeItem(name),
                                      ),
                                      Text("$qty",
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 20),
                                        onPressed: () => cart.addItem(name, price, imageUrl: imageUrl),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPriceRow("Subtotal", cart.totalPrice, formatter),
                _buildPriceRow("GST (5%)", gst, formatter),
                _buildPriceRow("Delivery Fee", deliveryFee, formatter),
                const Divider(height: 16),
                _buildPriceRow("Total", grandTotal, formatter, isBold: true),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: cart.totalItems > 0
                      ? () => _showPaymentDialog(context, cart)
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Place Order"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, NumberFormat formatter,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(formatter.format(amount),
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  void _showPaymentDialog(BuildContext context, CartManager cart) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Payment Method"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text("Credit / Debit Card"),
                onTap: () {
                  Navigator.pop(context);
                  _completeOrder(context, cart, "Credit / Debit Card");
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Wallet / UPI"),
                onTap: () {
                  Navigator.pop(context);
                  _completeOrder(context, cart, "Wallet / UPI");
                },
              ),
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text("Cash on Delivery"),
                onTap: () {
                  Navigator.pop(context);
                  _completeOrder(context, cart, "Cash on Delivery");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _completeOrder(BuildContext context, CartManager cart, String paymentMethod) {
    cart.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order placed! Payment Method: $paymentMethod")),
    );
  }
}

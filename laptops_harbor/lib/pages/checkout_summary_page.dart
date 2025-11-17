import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:laptops_harbor/models/cart.dart';
import 'package:laptops_harbor/models/product.dart';
import 'package:laptops_harbor/models/user.dart' as app_user;
import 'package:laptops_harbor/models/enums.dart';
import 'package:laptops_harbor/services/product_dao.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/services/user_dao.dart';
import 'package:laptops_harbor/services/cart_dao.dart';
import 'package:laptops_harbor/services/email_service.dart';
import 'package:laptops_harbor/widgets/loader.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';
import 'package:laptops_harbor/widgets/success_dialog.dart';
import 'package:firebase_database/firebase_database.dart';

class CheckoutSummaryPage extends StatefulWidget {
  final Cart cart;
  const CheckoutSummaryPage({super.key, required this.cart});

  @override
  State<CheckoutSummaryPage> createState() => _CheckoutSummaryPageState();
}

class _CheckoutSummaryPageState extends State<CheckoutSummaryPage> {
  final ProductDao productDao = ProductDao();
  final UserDao userDao = UserDao();

  Map<String, Product> _products = {};
  app_user.User? _userDetails;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    try {
      final auth = AuthService();
      final user = auth.currentUser;

      if (user != null) {
        _userDetails = await userDao.getUserById(user.uid);
      }

      Map<String, Product> temp = {};
      for (final entry in widget.cart.items.entries) {
        final snap = await productDao.getProductList().ref.child(entry.key).get();
        if (snap.exists && snap.value != null) {
          temp[entry.key] =
              Product.fromJson(Map<dynamic, dynamic>.from(snap.value as Map));
        }
      }

      setState(() {
        _products = temp;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _confirmOrder() async {
    if (_userDetails == null) return;

    setState(() => _loading = true);

    try {
      // Save order in Firebase
      final orderRef = FirebaseDatabase.instance.ref('orders').push();
      await orderRef.set({
        'userId': _userDetails! .uuid,
        'userEmail': _userDetails!.email,
        'userName': _userDetails!.username,
        'items': widget.cart.items.map((key, item) => MapEntry(key, {
              'productId': key, // Store the actual product ID
              'quantity': item.quantity ?? 1,
              'price': _products[key]?.price ?? 0.0,
              'status': OrderStatus.pending.toJson(),
            })),
        'totalAmount': widget.cart.totalAmount,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Clear cart
      await CartDao().clearCart(_userDetails!.uuid);

      // Send order confirmation email
      final emailSent = await EmailService.sendOrderConfirmationEmail(
        userName: _userDetails!.username,
        userEmail: _userDetails!.email,
        orderId: orderRef.key!,
        totalAmount: widget.cart.totalAmount,
        orderItems: widget.cart.items.map((key, item) => MapEntry(key, {
          'title': _products[key]?.title ?? '',
          'price': _products[key]?.price ?? 0,
          'quantity': item.quantity,
        })),
      );

      // Show confirmation dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            message: emailSent
              ? 'Order confirmed! Check your email for confirmation.'
              : 'Order confirmed! Email sending failed, but order saved.',
          ),
        ).then((_) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order', // Navigate to order page
            (route) => false, // Remove all previous routes
          );
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm order: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cyanBlue = Color(0xFF00BCD4);

    if (_loading) return const Scaffold(body: Loader());

    return Scaffold(
      drawer: laptopsharborHeader.buildDrawer(context),
      body: Column(
        children: [
          const laptopsharborHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 USER INFORMATION
                      if (_userDetails != null)
                        _buildUserInfoBox(_userDetails!, cyanBlue)
                      else
                        const Text(
                          'No user information found.',
                          style: TextStyle(color: Colors.grey),
                        ),

                      const SizedBox(height: 20),

                      // 🔹 PRODUCT SUMMARY
                      const Text(
                        'Product Summary',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cyanBlue,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...widget.cart.items.entries.map((entry) {
                        final product = _products[entry.key];
                        if (product == null) return const SizedBox();
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: cyanBlue, width: 1),
                          ),
                          child: ListTile(
                            leading: product.image.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(product.image),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag,
                                    color: cyanBlue, size: 50),
                            title: Text(
                              product.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Qty: ${entry.value.quantity} × \$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Text(
                              '\$${(product.price * (entry.value.quantity ?? 1)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: cyanBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),

                      const Divider(color: cyanBlue, thickness: 1, height: 30),

                      // 🔹 TOTAL AMOUNT
                      Center(
                        child: Text(
                          'Total: \$${widget.cart.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: cyanBlue),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🔹 CONFIRM ORDER BUTTON
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cyanBlue,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _userDetails == null ? null : _confirmOrder,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Confirm Order',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const laptopsharborfooter(),
        ],
      ),
    );
  }

  // 🔸 USER INFO BOX
  Widget _buildUserInfoBox(app_user.User user, Color cyanBlue) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cyanBlue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Information',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          const SizedBox(height: 10),
          Text('Username: ${user.username}', style: const TextStyle(fontSize: 16)),
          Text('Email: ${user.email}', style: const TextStyle(fontSize: 16)),
          Text('Shipping Address: ${user.shippingAddress}',
              style: const TextStyle(fontSize: 16)),
          Text('Payment Method: ${user.paymentMethod}',
              style: const TextStyle(fontSize: 16)),
          if (user.role.isNotEmpty)
            Text('Role: ${user.role}', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

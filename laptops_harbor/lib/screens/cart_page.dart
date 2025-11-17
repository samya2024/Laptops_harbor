import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:laptops_harbor/models/cart.dart';
import 'package:laptops_harbor/models/order.dart';
import 'package:laptops_harbor/models/enums.dart';
import 'package:laptops_harbor/models/product.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/services/cart_dao.dart';
import 'package:laptops_harbor/services/order_dao.dart';
import 'package:laptops_harbor/services/product_dao.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';
import 'package:laptops_harbor/widgets/loader.dart';
import 'package:laptops_harbor/pages/checkout_summary_page.dart';

class ProductCartPage extends StatefulWidget {
  const ProductCartPage({super.key});
  static const String routeName = '/product-cart';

  @override
  State<ProductCartPage> createState() => _ProductCartPageState();
}

class _ProductCartPageState extends State<ProductCartPage> {
  final CartDao cartDao = CartDao();
  final OrderDao orderDao = OrderDao();
  final ScrollController _scrollController = ScrollController();
  final Map<String, Product> _productCache = {};
  bool _loading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _userId = user?.uid;
  }

  Future<Product?> _getProduct(String productId) async {
    if (_productCache.containsKey(productId)) return _productCache[productId];
    final snap = await ProductDao().getProductList().ref.child(productId).get();
    if (snap.exists && snap.value != null) {
      final product = Product.fromJson(Map<dynamic, dynamic>.from(snap.value as Map));
      _productCache[productId] = product;
      return product;
    }
    return null;
  }

  Future<void> _updateQuantity(String cartKey, Cart cart, String productId, int delta) async {
    setState(() => _loading = true);
    final items = Map<String, CartItem>.from(cart.items);

    if (!items.containsKey(productId)) {
      setState(() => _loading = false);
      return;
    }

    final oldItem = items[productId]!;
    final newQty = (oldItem.quantity ?? 1) + delta;
    if (newQty < 1) {
      setState(() => _loading = false);
      return;
    }

    final product = await _getProduct(productId);
    if (product == null) {
      setState(() => _loading = false);
      return;
    }

    items[productId] = CartItem(productId: productId, quantity: newQty);

    double total = 0.0;
    for (final entry in items.entries) {
      final p = await _getProduct(entry.key);
      if (p != null) total += (entry.value.quantity ?? 1) * p.price;
    }

    final updatedCart = Cart(userId: cart.userId, items: items, totalAmount: total);
    await cartDao.updateCart(cartKey, updatedCart);
    setState(() => _loading = false);
  }

  Future<void> _deleteItem(String cartKey, Cart cart, String productId) async {
    setState(() => _loading = true);
    final items = Map<String, CartItem>.from(cart.items);
    items.remove(productId);

    double total = 0.0;
    for (final entry in items.entries) {
      final p = await _getProduct(entry.key);
      if (p != null) total += (entry.value.quantity ?? 1) * p.price;
    }

    if (items.isEmpty) {
      await cartDao.deleteCart(cartKey);
    } else {
      await cartDao.updateCart(cartKey, Cart(userId: cart.userId, items: items, totalAmount: total));
    }

    setState(() => _loading = false);
  }

  Future<void> _orderSingleItem(String cartKey, Cart cart, String productId) async {
    setState(() => _loading = true);
    final product = await _getProduct(productId);
    if (product == null) {
      setState(() => _loading = false);
      return;
    }

    final item = cart.items[productId];
    if (item == null) {
      setState(() => _loading = false);
      return;
    }

    final orderItems = {
      productId: OrderItem(
        productId: productId,
        quantity: item.quantity ?? 1,
        price: product.price,
        status: OrderStatus.pending,
      ),
    };

    final order = Order(
      userId: cart.userId,
      items: orderItems,
      totalAmount: (item.quantity ?? 1) * product.price,
    );
    orderDao.saveOrder(order);
    await _deleteItem(cartKey, cart, productId);

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ordered item and removed from cart')),
    );
  }

  // ✅ UPDATED CHECKOUT METHOD — Navigate to checkout summary page to review order before placing
  Future<void> _checkout(String cartKey, Cart cart) async {
    // Navigate to checkout summary page with cart data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutSummaryPage(cart: cart),
      ),
    );
  }

  Widget _buildCartItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final cart = Cart.fromJson(json);
    final cartKey = snapshot.key!;
    final items = cart.items;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.entries.map((entry) {
            final productId = entry.key;
            final item = entry.value;
            return FutureBuilder<Product?>(
              future: _getProduct(productId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }
                final product = snap.data!;
                return ListTile(
                  leading: product.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(product.image),
                            width: 40,
                            height: 60,
                            fit: BoxFit.fill,
                          ),
                        )
                      : const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                  title: Text(product.title),
                  subtitle: Text('Unit Price: \$${product.price.toStringAsFixed(2)} | Total: \$${ (product.price * (item.quantity ?? 1)).toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => _updateQuantity(cartKey, cart, productId, -1),
                      ),
                      Text('${item.quantity ?? 1}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _updateQuantity(cartKey, cart, productId, 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(cartKey, cart, productId),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart Total: ${cart.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () => _checkout(cartKey, cart),
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: laptopsharborHeader.buildDrawer(context),
      body: Column(
        children: [
          const laptopsharborHeader(),
          Expanded(
            child: Stack(
              children: [
                if (_loading) const Positioned.fill(child: Loader()),
                StreamBuilder(
                  stream: cartDao
                      .getCartList()
                      .orderByChild('userId')
                      .equalTo(_userId)
                      .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading cart.'));
                    }

                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return const Center(child: Text('No items in cart.'));
                    }

                    final carts = <MapEntry<String, dynamic>>[];
                    final map = Map<String, dynamic>.from(data as dynamic);
                    map.forEach((key, value) {
                      carts.add(MapEntry(key, value));
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: carts.length,
                      itemBuilder: (context, index) {
                        final entry = carts[index];
                        final snapshot = DataSnapshotFake(entry.key, entry.value);
                        return _buildCartItem(snapshot);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const laptopsharborfooter(),
        ],
      ),
    );
  }
}

// Helper class for fake DataSnapshot
class DataSnapshotFake implements DataSnapshot {
  @override
  final String? key;
  @override
  final dynamic value;
  DataSnapshotFake(this.key, this.value);

  @override
  bool get exists => value != null;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

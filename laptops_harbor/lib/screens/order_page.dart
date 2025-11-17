import 'package:flutter/material.dart';
import 'package:laptops_harbor/models/order.dart';
import 'package:laptops_harbor/services/order_dao.dart';
import 'package:laptops_harbor/services/product_dao.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:laptops_harbor/widgets/loader.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/models/enums.dart';
import 'package:laptops_harbor/models/product.dart';
import 'dart:convert';

class ProductOrderPage extends StatefulWidget {
  const ProductOrderPage({super.key});
  static const String routeName = '/product-order';

  @override
  State<ProductOrderPage> createState() => _ProductOrderPageState();
}

class _ProductOrderPageState extends State<ProductOrderPage> {
  final OrderDao orderDao = OrderDao();
  final ProductDao productDao = ProductDao();
  final ScrollController _scrollController = ScrollController();
  String? _userId;
  final _loading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _userId = user?.uid;
  }

  void _cancelOrder(String key, Order order, String itemKey) {
    // Update the order item status to canceled
    final updatedItems = Map<String, OrderItem>.from(order.items);
    final item = updatedItems[itemKey];
    if (item != null) {
      updatedItems[itemKey] = OrderItem(
        productId: item.productId, // same property used for productId
        quantity: item.quantity,
        price: item.price,
        status: OrderStatus.canceled,
      );
      final updatedOrder = Order(
        userId: order.userId,
        items: updatedItems,
        totalAmount: order.totalAmount,
      );
      orderDao.updateOrder(key, updatedOrder);
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order item cancelled.')),
        );
      }
    }
  }

  Widget _buildOrderItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final order = Order.fromJson(json);
    final orderKey = snapshot.key!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, idx) {
                final entry = order.items.entries.elementAt(idx);
                final orderItem = entry.value;
                final itemKey = entry.key;
                final isPending = orderItem.status == OrderStatus.pending;
                return FutureBuilder<Product?>(
                  future: productDao.getProductById(orderItem.productId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Loader());
                    }
                    final product = snapshot.data;
                    return ListTile(
                      leading: (product != null && product.image.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(product.image),
                                width: 40,
                                height: 60,
                                fit: BoxFit.fill,
                              ),
                            )
                          : const Icon(Icons.shopping_bag, size: 40),
                      title: Text(product?.title ?? 'Unknown Product'),
                      subtitle: Row(
                        children: [
                          Text('Quantity: ${orderItem.quantity}'),
                          const SizedBox(width: 12),
                          Text(
                            'Status: ${orderItem.status.toString().split('.').last}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (isPending)
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.orange,
                              ),
                              onPressed: () =>
                                  _cancelOrder(orderKey, order, itemKey),
                              tooltip: 'Cancel Order',
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
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
                  stream: orderDao
                      .getOrderList()
                      .orderByChild('userId')
                      .equalTo(_userId)
                      .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Error loading product orders.'));
                    }
                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return const Center(
                          child: Text('No product orders found.'));
                    }
                    final orders = <MapEntry<String, dynamic>>[];
                    final map = Map<String, dynamic>.from(data as dynamic);
                    map.forEach((key, value) {
                      orders.add(MapEntry(key, value));
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final entry = orders[index];
                        final snapshot = DataSnapshotFake(
                          entry.key,
                          entry.value,
                        );
                        return _buildOrderItem(snapshot);
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

// Helper class to simulate DataSnapshot for compatibility
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

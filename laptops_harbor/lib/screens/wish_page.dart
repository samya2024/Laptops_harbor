import 'dart:convert';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:laptops_harbor/models/wish.dart';
import 'package:laptops_harbor/services/wish_dao.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laptops_harbor/models/product.dart'; // ✅ Replaced Book with Product
import 'package:laptops_harbor/services/product_dao.dart'; // ✅ Replaced BookDao
import 'package:laptops_harbor/services/cart_dao.dart';
import 'package:laptops_harbor/widgets/loader.dart';

class WishPage extends StatefulWidget {
  const WishPage({super.key});
  static const String routeName = '/wishlist';

  @override
  State<WishPage> createState() => _WishPageState();
}

class _WishPageState extends State<WishPage> {
  final WishDao wishDao = WishDao();
  final ScrollController _scrollController = ScrollController();
  String? _userId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
  }

  /// ✅ Build each product card in wishlist
  Widget _buildProductTile(String productId) {
    return FutureBuilder<DataSnapshot>(
      future: ProductDao().getProductList().ref.child(productId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Loader();
        }
        if (snap.hasError) return const Text('Error loading product');
        if (!snap.hasData || !snap.data!.exists) {
          return ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.grey),
            title: Text('Product not found ($productId)'),
          );
        }

        final productJson = snap.data!.value as Map<dynamic, dynamic>;
        final product = Product.fromJson(productJson);

        // ✅ Same image logic (base64 decoding)
        Widget leading;
        if (product.image.isNotEmpty) {
          try {
            leading = ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(product.image),
                width: 40,
                height: 60,
                fit: BoxFit.fill,
              ),
            );
          } catch (_) {
            leading = const Icon(Icons.shopping_bag, color: Colors.grey);
          }
        } else {
          leading = const Icon(Icons.shopping_bag, color: Colors.grey);
        }

        return Card(
          color: Colors.pink[50],
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ListTile(
            leading: leading,
            title: Text(product.title),
            subtitle: Text(product.shortDesc),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₨${product.price.toStringAsFixed(2)}'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Add to Cart',
                  onPressed: _userId == null
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await CartDao().addToCart(
                            _userId!,
                            product,
                            1,
                            productId,
                          );
                          setState(() => _loading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          }
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove from Wishlist',
                  onPressed: _userId == null
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await wishDao.removeFromWishList(_userId!, productId);
                          setState(() => _loading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from wishlist'),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ Build full wishlist (list of product tiles)
  Widget _buildWishListProducts(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final wishList = WishList.fromJson(json);
    final productIds = wishList.items.values.map((wish) => wish.productId).toList();

    if (productIds.isEmpty) {
      return const Center(child: Text('No products in wishlist.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productIds.length,
      itemBuilder: (context, i) => _buildProductTile(productIds[i]),
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
                FirebaseAnimatedList(
                  controller: _scrollController,
                  query: wishDao
                      .getWishList()
                      .orderByChild('userId')
                      .equalTo(_userId),
                  itemBuilder: (context, snapshot, animation, index) {
                    return _buildWishListProducts(snapshot);
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

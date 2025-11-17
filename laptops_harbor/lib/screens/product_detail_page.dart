
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:laptops_harbor/models/product.dart';
import 'package:laptops_harbor/services/product_dao.dart';
import 'package:laptops_harbor/services/cart_dao.dart';
import 'package:laptops_harbor/services/wish_dao.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';
import 'package:laptops_harbor/widgets/loader.dart';


class ProductDetailPage extends StatefulWidget {
  final String productKey;
  const ProductDetailPage({super.key, required this.productKey});
  static const String routeName = '/product-detail';

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  String? _error;
  final _reviewCtrl = TextEditingController();
  int _rating = 0;
  bool _loading = false;

  User? get _user => AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('products/${widget.productKey}')
          .get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        if (data is Map) {
          setState(() {
            _product = Product.fromJson(Map<dynamic, dynamic>.from(data));
          });
        } else {
          setState(() => _error = "Invalid product data format.");
        }
      } else {
        setState(() => _error = "Product not found in database.");
      }
    } catch (e) {
      setState(() => _error = "Failed to load product: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_product == null) return;
    if (_rating == 0 || _reviewCtrl.text.trim().isEmpty) {
      setState(() => _error = "Please provide a rating and comment.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = _user!.uid;
      final review = Review(
        userId: userId,
        rating: _rating,
        comment: _reviewCtrl.text.trim(),
        likes: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final updatedReviews = Map<String, Review>.from(_product!.reviews);
      updatedReviews[userId] = review;

      final allRatings = updatedReviews.values.map((r) => r.rating).toList();
      final avg = allRatings.isEmpty
          ? 0.0
          : allRatings.reduce((a, b) => a + b) / allRatings.length;

      // 🟢 Explicitly build a new Product (no copyWith)
      final updatedProduct = Product(
        title: _product!.title,
        category: _product!.category,
        price: _product!.price,
        discountPercent: _product!.discountPercent,
        shortDesc: _product!.shortDesc,
        image: _product!.image,
        specs: _product!.specs,
        ratings: Ratings(average: avg, count: allRatings.length),
        reviews: updatedReviews,
      );

      ProductDao().updateProduct(widget.productKey, updatedProduct);

      setState(() {
        _product = updatedProduct;
        _reviewCtrl.clear();
        _rating = 0;
      });
    } catch (e) {
      setState(() => _error = "Failed to submit review: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _product == null) {
      return const Scaffold(body: Center(child: Loader()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_product == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final product = _product!;
    final image = product.image.isNotEmpty
        ? Image.memory(
            base64Decode(product.image),
            width: 160,
            height: 160,
            fit: BoxFit.cover,
          )
        : Container(
            width: 160,
            height: 160,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 60),
          );

    final reviews = product.reviews.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final canReview = _user != null;

    return Scaffold(
      drawer: laptopsharborHeader.buildDrawer(context),
      body: Column(
        children: [
          const laptopsharborHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      image,
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Category: ${product.category.name}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Rs. ${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (product.discountPercent > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      '-${product.discountPercent}%',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    color: Colors.amber[700], size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.ratings.average.toStringAsFixed(1)} '
                                  '(${product.ratings.count} reviews)',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shopping_cart),
                                  tooltip: 'Add to Cart',
                                  onPressed: _user == null
                                      ? null
                                      : () async {
                                          await CartDao().addToCart(
                                            _user!.uid,
                                            product,
                                            1,
                                            widget.productKey,
                                          );
                                          if (context.mounted) {
                                            Navigator.pushNamed(context, '/cart');
                                          }
                                        },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  tooltip: 'Add to Wishlist',
                                  onPressed: _user == null
                                      ? null
                                      : () async {
                                          await WishDao().addToWishList(
                                            _user!.uid,
                                            product,
                                            widget.productKey,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Added to wishlist')));
                                          }
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(product.shortDesc,
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 18),
                  const Divider(),
                  if (product.category.name.toLowerCase() == 'laptops')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Specifications',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        if (product.specs.isNotEmpty)
                          ...product.specs.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 15)),
                            ),
                          )
                        else
                          const Text('No specifications available.',
                              style: TextStyle(fontSize: 15, color: Colors.grey)),
                      ],
                    ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const Text(
                    'Reviews',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (reviews.isEmpty)
                    const Text('No reviews yet.',
                        style: TextStyle(color: Colors.grey)),
                  ...reviews.map(
                    (r) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(r.userId.isNotEmpty
                              ? r.userId[0].toUpperCase()
                              : '?'),
                        ),
                        title: Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber[700],
                              size: 18,
                            ),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.comment),
                            if (_user != null && r.userId == _user!.uid)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            _reviewCtrl.text = r.comment;
                                            setState(() {
                                              _rating = r.rating;
                                            });
                                          },
                                    child: const Text('Edit',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () async {
                                            final updatedReviews =
                                                Map<String, Review>.from(
                                                    _product!.reviews);
                                            updatedReviews.remove(_user!.uid);
                                            final allRatings =
                                                updatedReviews.values
                                                    .map((r) => r.rating)
                                                    .toList();
                                            final avg = allRatings.isEmpty
                                                ? 0.0
                                                : allRatings.reduce(
                                                        (a, b) => a + b) /
                                                    allRatings.length;
                                            final updatedProduct = Product(
                                              title: _product!.title,
                                              category: _product!.category,
                                              price: _product!.price,
                                              discountPercent: _product!
                                                  .discountPercent,
                                              shortDesc: _product!.shortDesc,
                                              image: _product!.image,
                                              specs: _product!.specs,
                                              ratings: Ratings(
                                                  average: avg,
                                                  count: allRatings.length),
                                              reviews: updatedReviews,
                                            );
                                            ProductDao().updateProduct(
                                                widget.productKey,
                                                updatedProduct);
                                            setState(() {
                                              _product = updatedProduct;
                                              _reviewCtrl.clear();
                                              _rating = 0;
                                            });
                                          },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: Text(
                          DateTime.fromMillisecondsSinceEpoch(r.createdAt)
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (canReview) ...[
                    const Divider(),
                    const Text('Add Your Review',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (i) => IconButton(
                          icon: Icon(
                            i < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber[700],
                          ),
                          onPressed: _loading
                              ? null
                              : () => setState(() => _rating = i + 1),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _reviewCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your review',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      enabled: !_loading,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitReview,
                      child: _loading
                          ? const SizedBox(
                              width: 18, height: 18, child: Loader())
                          : const Text('Submit Review'),
                    ),
                  ] else ...[
                    const Divider(),
                    const Text(
                      'Login to add your review.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const laptopsharborfooter(),
        ],
      ),
    );
  }
}

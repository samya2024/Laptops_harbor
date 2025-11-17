import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:laptops_harbor/models/product.dart';
import 'package:laptops_harbor/services/product_dao.dart';
import 'package:laptops_harbor/widgets/product_modal.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';
import 'package:laptops_harbor/screens/product_detail_page.dart';
import 'package:laptops_harbor/widgets/loader.dart';
import 'dart:convert';

class ManageProductPage extends StatefulWidget {
  const ManageProductPage({super.key});
  static const routeName = "/manage-products";

  @override
  State<ManageProductPage> createState() => _ManageProductPageState();
}

class _ManageProductPageState extends State<ManageProductPage> {
  final ProductDao productDao = ProductDao();
  final ScrollController _scrollController = ScrollController();

  void _showProductModal({Product? product, String? key}) {
    showDialog(
      context: context,
      builder: (ctx) => ProductModal(
        product: product,
        onSubmit: (newProduct) {
          if (key != null) {
            productDao.updateProduct(key, newProduct);
          } else {
            productDao.saveProduct(newProduct);
          }
          setState(() {});
        },
      ),
    );
  }

  void _deleteProduct(String key) {
    productDao.deleteProduct(key);
    setState(() {});
  }

  Widget _buildProductItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final product = Product.fromJson(json);

    // Handle both network and base64 images gracefully
    Widget imageWidget;
    if (product.image.isNotEmpty) {
      if (product.image.startsWith('data:image') ||
          RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(product.image)) {
        // Base64 encoded image
        try {
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.memory(
              base64Decode(product.image),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {
          imageWidget = const Icon(Icons.laptop, size: 60, color: Colors.grey);
        }
      } else {
        // Local asset or URL
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            product.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        );
      }
    } else {
      imageWidget = const Icon(Icons.laptop, size: 60, color: Colors.grey);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: imageWidget,
        title: Text(
          product.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '\$${product.price.toStringAsFixed(2)} • ${product.category.name}',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailPage(productKey: snapshot.key!),
            ),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showProductModal(
                product: product,
                key: snapshot.key,
              ),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProduct(snapshot.key!),
              tooltip: 'Delete',
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
                StreamBuilder(
                  stream: productDao.getProductList().onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Positioned.fill(child: Loader());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Error loading products'));
                    }
                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return const Center(child: Text('No products found.'));
                    }

                    final products = <MapEntry<String, dynamic>>[];
                    final map = Map<String, dynamic>.from(data as dynamic);
                    map.forEach((key, value) {
                      products.add(MapEntry(key, value));
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final entry = products[index];
                        final snapshot = DataSnapshotFake(
                          entry.key,
                          entry.value,
                        );
                        return _buildProductItem(snapshot);
                      },
                    );
                  },
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showProductModal(),
                    tooltip: 'Add Product',
                    child: const Icon(Icons.add),
                  ),
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

/// Helper class to simulate DataSnapshot for ListView
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

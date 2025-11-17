import 'package:firebase_database/firebase_database.dart';
import 'package:laptops_harbor/models/product.dart'; // <-- Update with your actual import path

class ProductDao {
  final _databaseRef = FirebaseDatabase.instance.ref("products");

  /// Save a new product to Firebase
  void saveProduct(Product product) {
    _databaseRef.push().set(product.toJson());
  }

  /// Get a list (Query) of all products
  Query getProductList() {
    return _databaseRef;
  }

  /// Delete a product by its key (Firebase generated ID)
  void deleteProduct(String key) {
    _databaseRef.child(key).remove();
  }

  /// Update an existing product
  void updateProduct(String key, Product product) {
    _databaseRef.child(key).update(product.toMap());
  }

  /// Fetch a single product by its Firebase key
  Future<Product?> getProductById(String productId) async {
    final snapshot = await _databaseRef.child(productId).get();
    if (snapshot.exists) {
      return Product.fromJson(snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }
}

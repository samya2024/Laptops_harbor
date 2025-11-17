import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:laptops_harbor/models/product.dart';
import 'package:laptops_harbor/models/cart.dart';
import 'package:laptops_harbor/models/order.dart';
import 'package:laptops_harbor/models/wish.dart';

class OfflineService {
  static const String _productsKey = 'offline_products';
  static const String _cartKey = 'offline_cart';
  static const String _ordersKey = 'offline_orders';
  static const String _wishlistKey = 'offline_wishlist';
  static const String _pendingActionsKey = 'pending_actions';

  // Check connectivity
  static Future<bool> isOnline() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // Save products for offline access
  static Future<void> cacheProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = products.map((product) => product.toJson()).toList();
    await prefs.setString(_productsKey, jsonEncode(productsJson));
  }

  // Get cached products
  static Future<List<Product>> getCachedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);
    if (productsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(productsJson);
    return decoded.map((json) => Product.fromJson(json)).toList();
  }

  // Save cart for offline access
  static Future<void> cacheCart(Cart cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart.toJson()));
  }

  // Get cached cart
  static Future<Cart?> getCachedCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson == null) return null;

    return Cart.fromJson(jsonDecode(cartJson));
  }

  // Save orders for offline access
  static Future<void> cacheOrders(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = orders.map((order) => order.toJson()).toList();
    await prefs.setString(_ordersKey, jsonEncode(ordersJson));
  }

  // Get cached orders
  static Future<List<Order>> getCachedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString(_ordersKey);
    if (ordersJson == null) return [];

    final List<dynamic> decoded = jsonDecode(ordersJson);
    return decoded.map((json) => Order.fromJson(json)).toList();
  }

  // Save wishlist for offline access
  static Future<void> cacheWishlist(WishList wishlist) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wishlistKey, jsonEncode(wishlist.toJson()));
  }

  // Get cached wishlist
  static Future<WishList?> getCachedWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getString(_wishlistKey);
    if (wishlistJson == null) return null;

    return WishList.fromJson(jsonDecode(wishlistJson));
  }

  // Save pending actions
  static Future<void> savePendingAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    pendingActions.add(
      jsonEncode({
        'action': action,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList(_pendingActionsKey, pendingActions);
  }

  // Get pending actions
  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    return pendingActions
        .map((action) => jsonDecode(action) as Map<String, dynamic>)
        .toList();
  }

  // Clear pending actions
  static Future<void> clearPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingActionsKey);
  }

  // Clear all cached data
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_productsKey);
    await prefs.remove(_cartKey);
    await prefs.remove(_ordersKey);
    await prefs.remove(_wishlistKey);
    await prefs.remove(_pendingActionsKey);
  }
}

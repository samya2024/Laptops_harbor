import 'package:laptops_harbor/screens/manage_product_page.dart';
import 'package:laptops_harbor/screens/manage_user.dart';
import 'package:laptops_harbor/screens/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:laptops_harbor/screens/contact_us_page.dart';
import 'package:laptops_harbor/screens/home_page.dart';
import 'package:laptops_harbor/screens/auth_page.dart';
import 'package:laptops_harbor/pages/auth/logout.dart';
import 'package:laptops_harbor/screens/about_us_page.dart';
import 'package:laptops_harbor/screens/faq_page.dart';
import 'package:laptops_harbor/screens/search_page.dart';
import 'package:laptops_harbor/screens/cart_page.dart';
import 'package:laptops_harbor/screens/wish_page.dart';
import 'package:laptops_harbor/screens/order_page.dart';
import 'package:laptops_harbor/screens/profile_page.dart';
import 'package:laptops_harbor/screens/manage_category_page.dart';
import 'package:laptops_harbor/screens/manage_order_page.dart';
import 'package:laptops_harbor/screens/manage_contact_us_page.dart';


import '../pages/splash_pages.dart';
import '../pages/auth/admin_home.dart';
// Public routes (no authentication required)
final Map<String, WidgetBuilder> publicRoutes = {
  '/': (context) => const HomePage(),
  '/auth': (context) => const AuthPage(),
  '/contact-us': (context) => const ContactUsPage(),
  '/about-us': (context) => const AboutUsPage(),
  '/faq': (context) => const FAQPage(),
  '/search': (context) => const SearchPage(),
  '/splash': (context) => const SplashPage(),

  '/product-detail':
      (context) => ProductDetailPage(
        productKey:
            (ModalRoute.of(context)?.settings.arguments as Map?)?['productKey'] ??
            '',
      ),
};

// Protected routes (authentication required)
final Map<String, WidgetBuilder> protectedRoutes = {
  '/logout': (context) => const Logout(),
  '/cart': (context) => const ProductCartPage(),
  '/wishlist': (context) => const WishPage(),
  '/order': (context) => const ProductOrderPage(),
  '/profile': (context) => const ProfilePage(),

};

// Admin routes (admin access required)
final Map<String, WidgetBuilder> adminRoutes = {
  '/admin_home': (context) => const AdminHomePage(),
  '/manage-categories': (context) => const ManageCategoryPage(),
  '/manage-orders': (context) => const ManageProductOrderPage(),
  '/manage-products': (context) => const ManageProductPage(),
  '/manage-contact-us': (context) => const ManageContactUsPage(),
  '/manage-user': (context) => const ManageUsersPage(),


};

// Combined routes map
final Map<String, WidgetBuilder> routes = {
  ...publicRoutes,
  ...protectedRoutes,
  ...adminRoutes,
};

// List of routes that do NOT require authentication
const List<String> unprotectedRoutes = [
  '/',
  '/auth',
  '/contact-us',
  '/about-us',
  '/search',
  '/faq',
  '/product-detail',
];

// List of routes that DO require authentication
const List<String> protectedRoutesList = [
  '/logout',
  '/cart',
  '/wishlist',
  '/order',
  '/profile',
];

// List of routes that ONLY admin users can access
const List<String> adminOnlyRoutes = [
  '/admin_home',
  '/manage-products',
  '/manage-categories',
  '/manage-orders',
  '/manage-contact-us',
  '/manage-user',
 
];

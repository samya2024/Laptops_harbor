import 'package:flutter/material.dart';
import 'package:laptops_harbor/style/theme.dart';
import 'package:laptops_harbor/services/user_dao.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/widgets/animated_logo.dart';
import 'package:laptops_harbor/widgets/popup.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: camel_case_types
class laptopsharborHeader extends StatelessWidget {
  const laptopsharborHeader({super.key});

  Future<String?> _getUserRole() async {
    final user = AuthService().currentUser;
    if (user == null) return null;

    // First try to get from cache
    final prefs = await SharedPreferences.getInstance();
    final cachedRole = prefs.getString('user_role_${user.uid}');
    if (cachedRole != null) {
      return cachedRole;
    }

    // If not in cache, get from database and cache it
    final role = await UserDao().getUserRole(user.uid);
    if (role != null) {
      await prefs.setString('user_role_${user.uid}', role);
    }
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // smaller header
      color: Colors.cyan,
      padding: const EdgeInsets.symmetric(horizontal: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: black,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          const SizedBox(width: 1), // closer to menu toggle
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: Hero(
              tag: "logo_header",
              child: AnimatedLogo(size: 50), // smaller logo
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            color: black,
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            color: black,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: black,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_role_${AuthService().currentUser?.uid}');
              await showAppPopup(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/logout');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Method to build the drawer - call this from your main screen
  static Widget buildDrawer(BuildContext context) {
    final user = AuthService().currentUser;

    return Drawer(
      child: user == null
          ? ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: cyan),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: "logo_1",
                          child: AnimatedLogo(
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'LaptopHarbor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...DrawerItems.guestItems.map(
                  (item) => ListTile(
                    leading: Icon(item.icon, color: cyan),
                    title: Text(item.label),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, item.route);
                    },
                  ),
                ),
              ],
            )
          : _RoleBasedDrawer(),
    );
  }
}

class _RoleBasedDrawer extends StatefulWidget {
  @override
  __RoleBasedDrawerState createState() => __RoleBasedDrawerState();
}

class __RoleBasedDrawerState extends State<_RoleBasedDrawer> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        // Try to get from cache first
        final prefs = await SharedPreferences.getInstance();
        final cachedRole = prefs.getString('user_role_${user.uid}');
        if (cachedRole != null) {
          setState(() {
            _userRole = cachedRole;
            _isLoading = false;
          });
        } else {
          // If not in cache, fetch from database
          final role = await UserDao().getUserRole(user.uid);
          if (role != null) {
            await prefs.setString('user_role_${user.uid}', role);
          }
          setState(() {
            _userRole = role;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAdmin = _userRole == 'admin';
    final drawerItems = isAdmin ? DrawerItems.adminItems : DrawerItems.userItems;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: cyan),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "logo_2",
                  child: AnimatedLogo(
                    size: 80,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'LaptopHarbor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        ...drawerItems.map(
          (item) => ListTile(
            leading: Icon(item.icon, color: cyan),
            title: Text(item.label),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, item.route);
            },
          ),
        ),
      ],
    );
  }
}

class DrawerItems {
  static final List<_DrawerItem> adminItems = [
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(label: 'Contact Us', icon: Icons.support_agent, route: '/contact-us'),
    _DrawerItem(label: 'FAQ', icon: Icons.help_outline, route: '/faq'),
    _DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    _DrawerItem(label: 'Wishlist', icon: Icons.favorite_border, route: '/wishlist'),
    _DrawerItem(label: 'Order', icon: Icons.receipt_long, route: '/order'),
    _DrawerItem(label: 'Profile', icon: Icons.account_circle_outlined, route: '/profile'),
    _DrawerItem(label: 'Manage Products', icon: Icons.inventory, route: '/manage-products'),
    _DrawerItem(label: 'Manage Categories', icon: Icons.category, route: '/manage-categories'),
    _DrawerItem(label: 'Manage Orders', icon: Icons.rule_folder, route: '/manage-orders'),
    _DrawerItem(label: 'Manage Contact Us', icon: Icons.mark_email_read, route: '/manage-contact-us'),
  ];

  static final List<_DrawerItem> userItems = [
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(label: 'Contact Us', icon: Icons.support_agent, route: '/contact-us'),
    _DrawerItem(label: 'FAQ', icon: Icons.help_outline, route: '/faq'),
    _DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    _DrawerItem(label: 'Wishlist', icon: Icons.favorite_border, route: '/wishlist'),
    _DrawerItem(label: 'Order', icon: Icons.receipt_long, route: '/order'),
    _DrawerItem(label: 'Profile', icon: Icons.account_circle_outlined, route: '/profile'),
  ];

  static final List<_DrawerItem> guestItems = [
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(label: 'Contact Us', icon: Icons.support_agent, route: '/contact-us'),
    _DrawerItem(label: 'FAQ', icon: Icons.help_outline, route: '/faq'),
    _DrawerItem(label: 'Login', icon: Icons.login, route: '/auth'),
  ];
}

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

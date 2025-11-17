import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:laptops_harbor/models/user.dart';
import 'package:laptops_harbor/services/user_dao.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final UserDao _userDao = UserDao();
  User? _currentUser;
  bool _isLoading = true;

  int totalUsers = 0;
  int totalProducts = 0;
  int totalOrders = 0;

  final modules = [
    {
      'title': 'Manage Products',
      'icon': Icons.shopping_bag_outlined,
      'route': '/manage-products',
    },
    {
      'title': 'Manage Categories',
      'icon': Icons.category_outlined,
      'route': '/manage-categories',
    },
    {
      'title': 'Manage Orders',
      'icon': Icons.receipt_long_outlined,
      'route': '/manage-orders',
    },
    {
      'title': 'Manage Contact Us',
      'icon': Icons.contact_mail_outlined,
      'route': '/manage-contact-us',
    },
    {
  'title': 'Manage Users',
  'icon': Icons.supervised_user_circle_outlined,
  'route': '/manage-user',
},

  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDashboardStats();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userData = await _userDao.getUserById(currentUser.uid);
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final db = FirebaseDatabase.instance.ref();
      final usersSnap = await db.child('users').get();
      final productsSnap = await db.child('products').get();
      final ordersSnap = await db.child('orders').get();

      setState(() {
        totalUsers = usersSnap.children.length;
        totalProducts = productsSnap.children.length;
        totalOrders = ordersSnap.children.length;
      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF00BCD4),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Stats',
            onPressed: _loadDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              auth.FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 600 ? 2 : 1;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 Admin Info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.admin_panel_settings,
                                  size: 35, color: Color(0xFF00BCD4)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentUser?.username ?? 'Admin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentUser?.email ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Role: ${_currentUser?.role ?? 'Admin'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 📊 Stats Section
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWideScreen ? 3 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildStatCard('Total Users', totalUsers, Icons.people),
                          _buildStatCard('Total Products', totalProducts, Icons.shopping_bag),
                          _buildStatCard('Total Orders', totalOrders, Icons.receipt_long),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ⚙️ Admin Modules
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: modules.map((module) {
                          return _buildModuleCard(module);
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF00BCD4).withOpacity(0.1),
              child: Icon(icon, color: const Color(0xFF00BCD4)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  Text('$value',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BCD4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, module['route'] as String);
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                module['icon'] as IconData,
                size: 50,
                color: const Color(0xFF00BCD4),
              ),
              const SizedBox(height: 16),
              Text(
                module['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/services/category_dao.dart';
import 'package:laptops_harbor/services/order_dao.dart';
import 'package:laptops_harbor/services/product_dao.dart';
import 'package:laptops_harbor/services/user_dao.dart';
import 'package:laptops_harbor/models/product.dart';
import 'package:laptops_harbor/models/order.dart';
import 'package:laptops_harbor/models/user.dart';
import 'package:laptops_harbor/widgets/animated_logo.dart';
import 'package:laptops_harbor/data/add_demo_products.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final cyan = const Color(0xFF00BCD4);
  List<Category> categories = [];
  List<Order> orders = [];
  List<User> users = [];
  List<Product> products = [];
  List<String> imagePaths = [
    'assets/img1.webp',
    'assets/img2.webp',
    'assets/img3.webp',
    'assets/img4.webp',
    'assets/img5.webp',
  ];
  bool isLoading = true;
  String? currentUserEmail;
  String? selectedCategory;
  int onlineUsersCount = 0;
  DatabaseReference? onlineUsersRef;
  Stream<DatabaseEvent>? onlineUsersStream;

  @override
  void initState() {
    super.initState();
     _checkLoginStatus();
    _loadData();
    _listenOnlineUsers();
  }
  Future<void> _checkLoginStatus() async {
  final currentUser = AuthService().currentUser;
  if (currentUser == null) {
    // User not logged in, redirect to login page
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/auth'); // your login route
    }
  }
}

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final categoryDao = CategoryDao();
      final orderDao = OrderDao();
      final userDao = UserDao();
      final productDao = ProductDao();

      final categoriesSnapshot = await categoryDao.getAllCategories();
      final ordersSnapshot = await orderDao.getOrderList().get();
      final usersSnapshot = await userDao.getUserList().get();
      final productsSnapshot = await productDao.getProductList().get();

      // Get current user email
      final currentUser = AuthService().currentUser;
      final userEmail = currentUser?.email;

      // Parse users with error handling
      final parsedUsers = <User>[];
      for (final child in usersSnapshot.children) {
        try {
          final user = User.fromJson(child.value as Map<dynamic, dynamic>);
          parsedUsers.add(user);
        } catch (e) {
        }
      }

      setState(() {
        categories = categoriesSnapshot;
        orders = ordersSnapshot.children
            .map((child) => Order.fromJson(child.value as Map<dynamic, dynamic>))
            .toList();
        users = parsedUsers;
        products = productsSnapshot.children
            .map((child) => Product.fromJson(child.value as Map<dynamic, dynamic>))
            .toList();
        currentUserEmail = userEmail;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _listenOnlineUsers() {
    onlineUsersRef = FirebaseDatabase.instance.ref('online_users');
    onlineUsersStream = onlineUsersRef!.onValue;
    onlineUsersStream!.listen((event) {
      final snapshot = event.snapshot;
      setState(() {
        onlineUsersCount = snapshot.children.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cyan,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          )
        ],
      ),
      drawer: _buildDrawer(),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      currentUserEmail != null
                          ? 'Logged in as: $currentUserEmail'
                          : 'Loading user info...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Add Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cyan,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _addDemoProducts,
                        icon: const Icon(Icons.add_box),
                        label: const Text('Add Demo Products'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Today\'s Money',
                            _calculateTodaysMoney(), '+55%', Icons.money, Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('Registered Users', users.length.toString(),
                            '+3%', Icons.people, Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            'New Clients', '+3,462', '-2%', Icons.person_add, Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('Sales', orders.length.toString(), '+5%',
                            Icons.shopping_cart, Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('Online Users', onlineUsersCount.toString(), '+0%',
                            Icons.circle, Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSalesOverview(),


                  const SizedBox(height: 30),
                  _buildCategoriesCard(),
                  const SizedBox(height: 30),
                  _buildProductsCard(),
                  const SizedBox(height: 30),
                  _buildUsersCard(),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      '© 2023 Laptops Harbor. Made with ❤️',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ───────────────────────────── User Section ─────────────────────────────
  Widget _buildUsersCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Registered Users',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/manage-user'),
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            users.isEmpty
                ? const Text('No users found.')
                : Column(
                    children: users
                        .map((user) => ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(user.username ?? 'No name'),
                              subtitle: Text(user.email ?? 'No email'),
                              trailing: Text(
                                user.role ?? 'user',
                                style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── Drawer ─────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF00BCD4)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "logo_admin",
                  child: AnimatedLogo(size: 80),
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
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () => Navigator.pushNamed(context, '/manage-user'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Manage Products'),
            onTap: () => Navigator.pushNamed(context, '/manage-products'),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            onTap: () => Navigator.pushNamed(context, '/manage-categories'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Manage Orders'),
            onTap: () => Navigator.pushNamed(context, '/manage-orders'),
          ),
          ListTile(
            leading: const Icon(Icons.contact_mail),
            title: const Text('Manage Contact Us'),
            onTap: () => Navigator.pushNamed(context, '/manage-contact-us'),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Manage Feedbacks'),
            onTap: () => Navigator.pushNamed(context, '/manage-feedbacks'),
          )
        ],

      ),
    );
  }

  // ───────────────────────────── Products Section ─────────────────────────────
  Widget _buildProductsCard() {
    // Filter products based on selected category
    final filteredProducts = selectedCategory == null
        ? products
        : products.where((p) => p.category.name == selectedCategory).toList();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  hint: const Text('Filter by Category'),
                  value: selectedCategory,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((cat) => DropdownMenuItem<String>(
                          value: cat.name,
                          child: Text(cat.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            filteredProducts.isEmpty
                ? const Text('No products found.')
                : Column(
                    children: filteredProducts.take(5).map((product) => ListTile(
                          leading: const Icon(Icons.inventory),
                          title: Text(product.title ?? 'No title'),
                          subtitle: Text('\$${product.price?.toStringAsFixed(2) ?? '0.00'}'),
                          trailing: Text(
                            product.category.name ?? 'No category',
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }



  // ───────────────────────────── Helpers ─────────────────────────────
  Widget _buildSalesOverview() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('+4% more in 2021',
                style: TextStyle(color: Colors.green)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 100),
                        FlSpot(1, 120),
                        FlSpot(2, 140),
                        FlSpot(3, 160),
                        FlSpot(4, 180),
                        FlSpot(5, 200),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoriesCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._buildCategoryItems(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imagePaths.add(image.path);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image added: ${image.name}')));
    }
  }

  Future<void> _addDemoProducts() async {
    try {
      addDemoProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo products added successfully!')),
      );
      // Reload data to show new products
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding demo products: $e')),
      );
    }
  }

  Widget _buildStatCard(String title, String value, String change, IconData icon, Color color) {
    return GestureDetector(
      onTap: _showCurrentUserInfo,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(change, style: TextStyle(color: change.startsWith('+') ? Colors.green : Colors.red, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrentUserInfo() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final userDao = UserDao();
      final userDetails = await userDao.getUserById(user.uid);
      if (userDetails != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Current User Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: ${userDetails.username}'),
                Text('Email: ${userDetails.email}'),
                Text('Role: ${userDetails.role}'),
                Text('UUID: ${userDetails.uuid}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }


  String _calculateTodaysMoney() {
    double total = 0.0;
    for (var order in orders) {
      total += order.totalAmount;
    }
    return '\$${total.toStringAsFixed(0)}';
  }

  List<Widget> _buildCategoryItems() {
    return categories.map((category) {
      int inStock =
          products.where((p) => p.category.id == category.id).length;
      int sold = orders
          .expand((o) => o.items.values)
          .where((item) =>
              products.any((p) => p.title == item.productId))
          .length;
      return ListTile(
        leading: const Icon(Icons.category),
        title: Text(category.name),
        subtitle: Text('$inStock in stock, $sold+ sold'),
      );
    }).toList();
  }
}

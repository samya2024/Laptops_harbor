import 'package:flutter/material.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';
import 'package:laptops_harbor/style/theme.dart';
import 'package:laptops_harbor/services/product_dao.dart';
import 'package:laptops_harbor/models/product.dart';
import 'package:laptops_harbor/widgets/loader.dart';
import 'package:laptops_harbor/screens/product_detail_page.dart';
import 'package:laptops_harbor/screens/search_page.dart';
import 'dart:convert';
import 'dart:math';
import 'package:laptops_harbor/services/category_constants.dart';
import 'package:laptops_harbor/widgets/info_cards.dart';
import 'package:laptops_harbor/widgets/popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProductWithKey {
  final String key;
  final Product product;

  ProductWithKey({required this.key, required this.product});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const String routeName = '/';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ProductWithKey> _allProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    // Try to load from cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedProducts = prefs.getString('cached_home_products');

    if (cachedProducts != null) {
      try {
        final cachedData = jsonDecode(cachedProducts) as List;
        final List<ProductWithKey> cachedProductList = cachedData.map((item) {
          final productData = item['product'] as Map<String, dynamic>;
          final key = item['key'] as String;
          final product = Product.fromJson(productData);
          return ProductWithKey(key: key, product: product);
        }).toList();

        if (mounted) {
          setState(() {
            _allProducts = cachedProductList;
            _loading = false;
          });
        }
      } catch (e) {
        // If cache parsing fails, continue to load from database
      }
    }

    // Load fresh data from database
    final productDao = ProductDao();
    productDao.getProductList().onValue.listen(
      (event) async {
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          final products = <ProductWithKey>[];
          data.entries.forEach((entry) {
            try {
              final productData = Map<String, dynamic>.from(entry.value as Map);
              final product = Product.fromJson(productData);
              products.add(ProductWithKey(
                key: entry.key,
                product: product,
              ));
            } catch (e) {
            }
          });

          // Cache the fresh data
          final cacheData = products.map((p) => {
            'key': p.key,
            'product': p.product.toJson(),
          }).toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_home_products', jsonEncode(cacheData));

          if (mounted) {
            setState(() {
              _allProducts = products;
              _loading = false;
            });
          }
        } else {
          debugPrint("HomePage: No products found");
          if (mounted) {
            setState(() {
              _allProducts = [];
              _loading = false;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      },
    );
  }

  List<ProductWithKey> _getNewArrivals() {
    // Show all products as new arrivals for now, or filter by recent addition
    return _allProducts.take(4).toList(); // Show first 4 products as new arrivals
  }

  List<ProductWithKey> _getBestSellers() {
    // Show products with ratings >= 3.0 as best sellers, or all if none qualify
    final bestSellers = _allProducts.where((p) => p.product.ratings.average >= 3.0).toList();
    return bestSellers.isNotEmpty ? bestSellers.take(4).toList() : _allProducts.take(4).toList();
  }

  List<ProductWithKey> _getRecommended() {
    final random = Random();
    final allProducts = [..._allProducts];
    allProducts.shuffle(random);
    return allProducts.take(4).toList();
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
                if (_loading && _allProducts.isEmpty) const Positioned.fill(child: Loader()),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroBanner(),
                        const SizedBox(height: 40),

                        _buildSectionTitle('New Arrivals', color: black),

                        const SizedBox(height: 16),
                        _buildProductScroll(_getNewArrivals()),
                        const SizedBox(height: 20),
                        _buildLargeImageContainer(),
                        const SizedBox(height: 30),
                        _buildSectionTitle(
                          'Best Selling Products',
                          color: Colors.black,
                        ),
                        const SizedBox(height: 16),
                        _buildProductScroll(_getBestSellers()),
                        const SizedBox(height: 30),
                        _buildSectionTitle(
                          'Recommended For You',
                          color: Colors.black,
                        ),
                        const SizedBox(height: 16),
                        _buildProductScroll(_getRecommended()),
                        const SizedBox(height: 30),
                        _buildSectionTitle('Categories', color: Colors.black),
                        const SizedBox(height: 16),
                        _buildCategoryScroll(),
                        const SizedBox(height: 30),
                        const InfoCard(
                          title: 'Why Quality Matters',
                          titleStyle: TextStyle(
                            fontWeight: FontWeight.bold, // Bold text
                            color: Colors.black, // Black color
                          ),
                          content:

                              'At Laptop Harbor, we bring you only the best products—carefully curated for performance, durability, and style.',
                        ),
                        const InfoCard(
                          title: 'Our Mission',
                          titleStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),

                          content:
                              'We aim to make premium tech accessible to everyone. Our team handpicks each product so you can shop with confidence.',
                        ),
                        const SizedBox(height: 30),
                        _buildSectionTitle('Subscribe to our newsletter', color: Colors.black),
                        const SizedBox(height: 12),
                        _buildNewsletterSignup(),
                        const SizedBox(height: 40),
                      ],
                    ),
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

  Widget _buildHeroBanner() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/laptops.webp',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // color: lightGrey,
              color: Colors.black.withValues(alpha: 102),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Upgrade your tech,\none gadget at a time.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
            ElevatedButton(
  style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan ,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
  ),
  onPressed: () async {
    // Show popup and wait for user to close it
    await showAppPopup(
      context,
      title: 'Welcome!',
      message: 'Explore the best laptops curated just for you.',
      imagePath: 'assets/ep 5.webp',
      customWidth: MediaQuery.of(context).size.width * 0.95,
    );
    if (!mounted) return;


    // Navigate to Search page after popup is closed
    Navigator.pushNamed(context, '/search');
  },
  child: const Text(
    'Browse Products',
    style: TextStyle(color: white, fontWeight: FontWeight.bold),
  ),
),
 ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {Color color = cyan}) {
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildProductScroll(List<ProductWithKey> products) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final productWithKey = products[index];
          final product = productWithKey.product;

          Widget imageWidget;
          if (product.image.isNotEmpty) {
            try {
              final imageBytes = base64Decode(product.image);
              imageWidget = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  width: 120,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              );
            } catch (_) {
              imageWidget = _placeholderImage();
            }
          } else {
            imageWidget = _placeholderImage();
          }

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailPage(productKey: productWithKey.key),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        imageWidget,
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            product.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: black,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            'Rs. ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(color: cyan, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 120,
      height: 150,
      color: Colors.cyan,
      child: const Icon(Icons.image, color: Colors.white70, size: 32),
    );
  }

  Widget _buildCategoryScroll() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kProductCategories.length, // or your product categories
        itemBuilder: (context, index) {
          final category = kProductCategories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Material(
                color: const Color.fromARGB(0, 0, 0, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                        settings: RouteSettings(arguments: category.label),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyan),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category.icon, color: cyan),
                        const SizedBox(width: 8),
                        Text(
                          category.label,
                          style: const TextStyle(
                            color: cyan,
                            fontWeight: FontWeight.bold


                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLargeImageContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/laptops.webp',
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildNewsletterSignup() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Email address',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: cyan,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: const Text('Subscribe', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

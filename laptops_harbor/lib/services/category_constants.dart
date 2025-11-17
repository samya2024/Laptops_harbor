import 'package:flutter/material.dart';

class ProductCategory {
  final String label;
  final IconData icon;
  const ProductCategory(this.label, this.icon);
}

const List<ProductCategory> kProductCategories = [
  ProductCategory('Laptops', Icons.laptop),
  ProductCategory('Business', Icons.business),
  ProductCategory('Gaming', Icons.sports_esports),
  ProductCategory('Accessories', Icons.headset),
  ProductCategory('Monitors', Icons.monitor),
  ProductCategory('Keyboards', Icons.keyboard),
  ProductCategory('Mouse', Icons.mouse),
  ProductCategory('Printers', Icons.print),
  ProductCategory('Networking', Icons.wifi),
  ProductCategory('Storage', Icons.sd_storage),
  ProductCategory('Software', Icons.code),
];

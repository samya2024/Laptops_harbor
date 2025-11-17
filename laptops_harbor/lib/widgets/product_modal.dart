import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:laptops_harbor/models/product.dart';

class ProductModal extends StatefulWidget {
  final Product? product;
  final void Function(Product product) onSubmit;

  const ProductModal({super.key, this.product, required this.onSubmit});

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _shortDescCtrl;
  late TextEditingController _discountCtrl;

  // Basic spec fields for simplicity
  late TextEditingController _cpuCtrl;
  late TextEditingController _ramCtrl;
  late TextEditingController _storageCtrl;
  late TextEditingController _displayCtrl;

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  Uint8List? _webImage;
  String? _imageBase64;

  late Category? _selectedCategory;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _shortDescCtrl = TextEditingController(text: p?.shortDesc ?? '');
    _discountCtrl = TextEditingController(
      text: p?.discountPercent.toString() ?? '0',
    );

    _cpuCtrl = TextEditingController(text: p?.specs['CPU'] ?? '');
    _ramCtrl = TextEditingController(text: p?.specs['RAM'] ?? '');
    _storageCtrl = TextEditingController(text: p?.specs['Storage'] ?? '');
    _displayCtrl = TextEditingController(text: p?.specs['Display'] ?? '');

    _selectedCategory = p?.category;
    _fetchCategories();

    if (p != null && p.image.isNotEmpty) {
      _imageBase64 = p.image;
      try {
        _webImage = base64Decode(p.image);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _shortDescCtrl.dispose();
    _discountCtrl.dispose();
    _cpuCtrl.dispose();
    _ramCtrl.dispose();
    _storageCtrl.dispose();
    _displayCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final snap = await FirebaseDatabase.instance.ref('categories').get();
    final data = snap.value;
    if (data != null) {
      final map = Map<String, dynamic>.from(data as dynamic);
      setState(() {
        _categories = map.values
            .map((v) => Category.fromJson(Map<String, dynamic>.from(v)))
            .toList();
        if (_selectedCategory == null && _categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageBase64 = base64Encode(bytes);
        });
      } else {
        final file = File(picked.path);
        setState(() {
          _selectedImage = file;
          _imageBase64 = base64Encode(file.readAsBytesSync());
        });
      }
    }
  }

  Widget _imagePreview() {
    return FormField<String>(
      validator: (value) {
        if (_imageBase64 == null || _imageBase64!.isEmpty) {
          return 'Please select a product image';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                width: 150,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    color: Colors.grey[200],
                    child: _webImage != null
                        ? Image.memory(_webImage!, fit: BoxFit.fill)
                        : _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.fill)
                        : const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
          ],
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        title: _titleCtrl.text,
        category: _selectedCategory!,
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
        image: _imageBase64 ?? '',
        shortDesc: _shortDescCtrl.text,
        specs: {
          'CPU': _cpuCtrl.text,
          'RAM': _ramCtrl.text,
          'Storage': _storageCtrl.text,
          'Display': _displayCtrl.text,
        },
        ratings: widget.product?.ratings ?? Ratings(average: 0, count: 0),
        discountPercent: int.tryParse(_discountCtrl.text) ?? 0,
        reviews: widget.product?.reviews ?? {},
      );

      widget.onSubmit(product);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return AlertDialog(
      title: Text(
        widget.product == null ? 'Add Product' : 'Edit Product',
        style: TextStyle(
          fontSize: isSmallScreen ? 20 : 24,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: isSmallScreen ? screenWidth * 0.9 : 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _imagePreview(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.title, color: Colors.cyan),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter product title'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        FormField<Category>(
                          initialValue: _selectedCategory,
                          validator: (v) =>
                              v == null ? 'Select category' : null,
                          builder: (field) {
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(
                                  Icons.category,
                                  color: Colors.cyan,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.cyan),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                errorText: field.errorText,
                              ),
                              child: DropdownButton<Category>(
                                value: field.value,
                                items: _categories
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (cat) {
                                  field.didChange(cat);
                                  setState(() => _selectedCategory = cat);
                                },
                                isExpanded: true,
                                underline: SizedBox(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: Colors.cyan,
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter price' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shortDescCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Short Description',
                            prefixIcon: Icon(
                              Icons.description,
                              color: Colors.cyan,
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter short description'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          'Specifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cpuCtrl,
                          decoration: const InputDecoration(
                            labelText: 'CPU',
                            prefixIcon: Icon(Icons.memory, color: Colors.cyan),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ramCtrl,
                          decoration: const InputDecoration(
                            labelText: 'RAM',
                            prefixIcon: Icon(
                              Icons.sd_storage,
                              color: Colors.cyan,
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _storageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Storage',
                            prefixIcon: Icon(Icons.storage, color: Colors.cyan),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _displayCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Display',
                            prefixIcon: Icon(Icons.monitor, color: Colors.cyan),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _discountCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Discount (%)',
                            prefixIcon: Icon(
                              Icons.discount,
                              color: Colors.cyan,
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter discount' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(widget.product == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

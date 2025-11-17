import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image/image.dart' as img;

class ImageService {
  static const int maxImageSize = 1024; // Max dimension for images
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB max file size

  // Optimize image before upload
  static Future<Uint8List> optimizeImage(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxFileSize) {
      throw Exception('Image size exceeds 2MB limit');
    }

    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image format');

    // Resize if needed
    var resized = image;
    if (image.width > maxImageSize || image.height > maxImageSize) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? maxImageSize : null,
        height: image.height > image.width ? maxImageSize : null,
      );
    }

    // Compress
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  // Optimize image from web
  static Future<Uint8List> optimizeWebImage(Uint8List bytes) async {
    if (bytes.length > maxFileSize) {
      throw Exception('Image size exceeds 2MB limit');
    }

    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image format');

    // Resize if needed
    var resized = image;
    if (image.width > maxImageSize || image.height > maxImageSize) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? maxImageSize : null,
        height: image.height > image.width ? maxImageSize : null,
      );
    }

    // Compress
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  // Cache image locally
  static Future<String> cacheImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image');
    }

    final bytes = response.bodyBytes;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // Get cached image widget
  static Widget getCachedImage(String url, {double? width, double? height}) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
    );
  }

  // Clear image cache
  static Future<void> clearImageCache() async {
    final dir = await getTemporaryDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

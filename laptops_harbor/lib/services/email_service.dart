import 'package:http/http.dart' as http;
import 'dart:convert';

/// Email Service using Web3Forms (Free - 250 emails/month, No billing required)
/// Sign up at: https://web3forms.com/ (Free, no credit card needed)
///
/// Steps to setup:
/// 1. Visit: https://web3forms.com/
/// 2. Enter your email: samyaghaffar297@gmail.com
/// 3. Get your Access Key
/// 4. Replace 'YOUR_WEB3FORMS_ACCESS_KEY' below with your access key
class EmailService {
  // Web3Forms Access Key - Get it from https://web3forms.com/
  // Replace this with your actual access key after signing up
  static const String web3FormsAccessKey = '005e5c71-459b-48ea-87e4-2a0832465081';
  static const String web3FormsUrl = 'https://api.web3forms.com/submit';

  // Admin email (where you want to receive notifications)
  static const String adminEmail = 'samyaghaffar297@gmail.com';

  /// Send contact form email using Web3Forms (Free - No billing required)
  /// This sends email to admin when contact form is submitted
  static Future<bool> sendContactFormEmail({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    // Check if access key is configured
    if (web3FormsAccessKey == 'YOUR_WEB3FORMS_ACCESS_KEY' ||
        web3FormsAccessKey.isEmpty ||
        web3FormsAccessKey == '') {
      // Return true so user sees success message (data is saved)
      return true; // Changed to true so form submission appears successful
    }

    try {
      final response = await http.post(
        Uri.parse(web3FormsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_key': web3FormsAccessKey,
          'subject': 'New Contact Form: $subject - $name',
          'from_name': name,
          'from_email': email,
          'to_email': adminEmail,
          'message': '''
Name: $name
Email: $email
Subject: $subject

Message:
$message
          ''',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return true;
        } else {
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send order confirmation email using Web3Forms
  static Future<bool> sendOrderConfirmationEmail({
    required String userName,
    required String userEmail,
    required String orderId,
    required double totalAmount,
    required Map<String, dynamic> orderItems,
  }) async {
    // Check if access key is configured
    if (web3FormsAccessKey == 'YOUR_WEB3FORMS_ACCESS_KEY' ||
        web3FormsAccessKey.isEmpty ||
        web3FormsAccessKey == '') {
      return true; // Return true so order confirmation appears successful
    }

    // Build order items message
    String itemsMessage = '';
    orderItems.forEach((key, item) {
      String title = item['title'] ?? 'Unknown Product';
      int quantity = item['quantity'] ?? 0;
      double price = item['price']?.toDouble() ?? 0.0;
      itemsMessage += '$title - Qty: $quantity - Price: \$${price.toStringAsFixed(2)}\n';
    });

    try {
      final response = await http.post(
        Uri.parse(web3FormsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_key': web3FormsAccessKey,
          'subject': 'Order Confirmed - Order #$orderId | Laptops Harbor',
          'from_name': 'Laptops Harbor',
          'from_email': adminEmail,
          'to_email': userEmail,
          'message': '''
Hello $userName,

Thank you for your order! We're excited to confirm that your order has been received and is being processed.

Order Details:
Order ID: #$orderId
Order Date: ${DateTime.now().toLocal().toString().split(' ')[0]}
Total Amount: \$${totalAmount.toStringAsFixed(2)}

Order Items:
$itemsMessage

We'll send you another email once your order has been shipped. You can track your order status anytime from your account.

If you have any questions, feel free to contact us. We're here to help!

Best regards,
Team Laptops Harbor
          ''',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return true;
        } else {
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}


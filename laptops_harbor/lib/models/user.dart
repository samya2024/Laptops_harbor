class User {
  final String uuid;
  final String role;
  final String shippingAddress;
  final String paymentMethod;
  final String username;
  final String email;

  User({
    required this.uuid,
    required this.role,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.username,
    required this.email,
  });

  User.fromJson(Map<dynamic, dynamic>? json)
    : uuid = json?['uuid'] as String? ?? '',
      role = json?['role'] as String? ?? '',
      shippingAddress = json?['shippingAddress'] as String? ?? '',
      paymentMethod = json?['paymentMethod'] as String? ?? '',
      username = json?['username'] as String? ?? '',
      email = json?['email'] as String? ?? '';

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'uuid': uuid,
    'role': role,
    'shippingAddress': shippingAddress,
    'paymentMethod': paymentMethod,
    'username': username,
    'email': email,
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'uuid': uuid,
    'role': role,
    'shippingAddress': shippingAddress,
    'paymentMethod': paymentMethod,
    'username': username,
    'email': email,
  };
}

import 'package:firebase_database/firebase_database.dart';
import 'demo_data.dart';

void addDemoProducts() {
  final databaseRef = FirebaseDatabase.instance.ref("products");
  for (final product in demoProducts) {
    databaseRef.push().set(product.toJson());
  }
}

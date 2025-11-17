import 'package:firebase_database/firebase_database.dart';
import 'package:laptops_harbor/models/user.dart';

class UserDao {
  final _databaseRef = FirebaseDatabase.instance.ref("users");

  // Save new user
  void saveUser(User user) {
    _databaseRef.push().set(user.toJson());
  }

  // Get all users (admin ya normal)
  Query getUserList() {
    return _databaseRef;
  }
  // ✅ Get all users (for Manage Users page)
Future<List<User>> getAllUsers() async {
  final snapshot = await _databaseRef.get();

  if (!snapshot.exists) return [];

  final usersList = <User>[];

  for (var child in snapshot.children) {
    final data = child.value as Map<dynamic, dynamic>;
    usersList.add(User.fromJson(data));
  }

  return usersList;
}


  // Delete a user by key
  void deleteUser(String key) {
    _databaseRef.child(key).remove();
  }
  // ✅ Delete user by UID (not just key)
Future<void> deleteUserByUid(String uid) async {
  final snapshot = await _databaseRef
      .orderByChild('uuid')
      .equalTo(uid)
      .limitToFirst(1)
      .get();

  if (snapshot.exists && snapshot.children.isNotEmpty) {
    final key = snapshot.children.first.key;
    await _databaseRef.child(key!).remove();
  }
}


  // Update user by key
  void updateUser(String key, User user) {
    _databaseRef.child(key).update(user.toMap());
  }

  // Get role of a user by UID (optional)
  Future<String?> getUserRole(String uid) async {
    final snapshot = await _databaseRef
        .orderByChild('uuid')
        .equalTo(uid)
        .limitToFirst(1)
        .get();

    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final userData = snapshot.children.first.value as Map<dynamic, dynamic>?;
      if (userData != null && userData['role'] is String) {
        return userData['role'] as String;
      }
    }
    return null;
  }

  // Get user by UID
  // ✅ This now returns admin or normal user in same way
  Future<User?> getUserById(String uid) async {
    final snapshot = await _databaseRef
        .orderByChild('uuid')
        .equalTo(uid)
        .limitToFirst(1)
        .get();

    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final userData = snapshot.children.first.value as Map<dynamic, dynamic>?;
      if (userData != null) {
        // Return user object directly, admin will also be returned here
        return User.fromJson(userData);
      }
    }
    return null;
  }

  // ✅ Optional: Get all admins if needed
  Future<List<User>> getAdmins() async {
    final snapshot = await _databaseRef
        .orderByChild('role')
        .equalTo('admin')
        .get();

    if (snapshot.exists) {
      return snapshot.children.map((child) {
        final data = child.value as Map<dynamic, dynamic>;
        return User.fromJson(data);
      }).toList();
    }
    return [];
  }
}

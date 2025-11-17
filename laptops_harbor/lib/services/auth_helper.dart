import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserData {
  final String email;
  final String username;

  UserData({required this.email, required this.username});

  Map<String, dynamic> toJson() => {
        'email': email,
        'username': username,
        'createdAt': ServerValue.timestamp, // Optional: Add a creation timestamp
      };
}


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // Register with email and password (remove displayName update)
  Future<User?> register(String email, String password, String username) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Do NOT update displayName here, only store username in DB
    return result.user;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Delete current user
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    await user?.delete();
  }

  // Update password for current user
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    await user?.updatePassword(newPassword);
  }

  // Send email verification to current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    await user?.sendEmailVerification();
  }

  // Update email for current user
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    // await user?.updateEmail(newEmail); // deprecated
    await user?.verifyBeforeUpdateEmail(newEmail);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}


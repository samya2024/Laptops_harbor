import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laptops_harbor/services/validate.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laptops_harbor/models/user.dart' as app_user;
import 'package:laptops_harbor/services/user_dao.dart';
import 'package:laptops_harbor/widgets/alert_error.dart';
import 'package:laptops_harbor/widgets/loader.dart';
import 'package:laptops_harbor/style/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _saveUserToPrefs(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('user_role_${uid}', role); // Cache role for faster loading
  }

  void _register() async {
    setState(() {
      _error = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      try {
        final user = await AuthService().register(
          _emailCtrl.text,
          _passCtrl.text,
          _nameCtrl.text,
        );
        if (user != null) {
          final userObj = app_user.User(
            uuid: user.uid,
            role: 'user',
            shippingAddress: '',
            paymentMethod: '',
            username: _nameCtrl.text,
            email: _emailCtrl.text,
          );

          final userDao = UserDao();
          userDao.saveUser(userObj);

          await _saveUserToPrefs(user.uid, 'user');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _error = e.message ?? "Registration failed");
      } catch (e) {
        setState(() => _error = "An unexpected error occurred");
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Loader()
        : SingleChildScrollView( // ✅ Prevents overflow on small screens
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AlertError(
                        _error!,
                        onClose: () => setState(() => _error = null),
                      ),
                    ),
                  // Username field
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: Color(0xFF8F8F8F)),
                      prefixIcon: Icon(Icons.person_outline, color: cyan),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8F8F8F)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cyan, width: 2),
                      ),
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: validateName,
                  ),
                  const SizedBox(height: 20),
                  // Email field
                  TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color(0xFF8F8F8F)),
                      prefixIcon: Icon(Icons.email_outlined, color: cyan),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8F8F8F)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cyan, width: 2),
                      ),
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 20),
                  // Password field
                  TextFormField(
                    controller: _passCtrl,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Color(0xFF8F8F8F)),
                      prefixIcon: Icon(Icons.lock_outline, color: cyan),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8F8F8F)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cyan, width: 2),
                      ),
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: validatePass,
                  ), // ✅ Added missing parenthesis
                  const SizedBox(height: 30),
                  // Register Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cyan, const Color(0xFF0097A7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

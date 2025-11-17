import 'package:flutter/material.dart';
import 'package:laptops_harbor/services/validate.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laptops_harbor/widgets/alert_error.dart';
import 'package:laptops_harbor/widgets/alert_success.dart';
import 'package:laptops_harbor/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Only for FirebaseAuthException
import 'package:laptops_harbor/services/user_dao.dart';
import 'package:laptops_harbor/style/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _saveUserToPrefs(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('user_role_${uid}', role); // Cache role for faster loading
  }

  void _login() async {
    setState(() {
      _error = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      try {
        final user = await AuthService().signIn(
          _emailCtrl.text,
          _passCtrl.text,
        );
        if (user != null) {
          // Verify user role
          final userDao = UserDao();
          final userRole = await userDao.getUserRole(user.uid);

          if (userRole == null) {
            setState(
              () => _error = "User role not found. Please contact support.",
            );
            return;
          }

          await _saveUserToPrefs(user.uid, userRole);
          if (userRole == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_home');
          } else {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _error = e.message ?? "Authentication failed");
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
        : Form(
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
                // Email field with icon
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
                // Password field with icon
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
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            final emailCtrl = TextEditingController(
                              text: _emailCtrl.text,
                            );
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reset Password'),
                                content: TextField(
                                  controller: emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter your email',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pop(emailCtrl.text),
                                    child: const Text('Send Reset Link'),
                                  ),
                                ],
                              ),
                            );
                            if (result != null && result.isNotEmpty) {
                              try {
                                await AuthService().sendPasswordResetEmail(
                                  result,
                                );
                                if (context.mounted) {
                                  // Show success alert
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: AlertSuccess(
                                        'Password reset email sent.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: AlertError(
                                        'Failed to send reset email: $e',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Gradient Login Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cyan,
                        const Color(0xFF0097A7),
                      ],
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
                    onPressed: _loading ? null : _login,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Login',
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
          );
  }
}

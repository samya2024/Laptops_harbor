import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/services/user_dao.dart';

/// Check if user is authenticated
Future<bool> _isAuthenticated() async {
  return AuthService().currentUser != null;
}

/// Get user role from Firebase
Future<String?> _getUserRole() async {
  final user = AuthService().currentUser;
  if (user == null) return null;
  return await UserDao().getUserRole(user.uid);
}

/// Guarded routing
Route<dynamic>? guardedRoute(RouteSettings settings) {
  final String? name = settings.name;
  final builder = routes[name];

  // Route not found
  if (builder == null) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Unknown route')),
      ),
    );
  }

  // Unprotected routes → directly show
  if (unprotectedRoutes.contains(name)) {
    return MaterialPageRoute(builder: builder);
  }

  // Admin-only routes → check authentication + role
  if (adminOnlyRoutes.contains(name)) {
    return MaterialPageRoute(
      builder: (context) => FutureBuilder<bool>(
        future: _isAuthenticated(),
        builder: (context, authSnapshot) {
          if (!authSnapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!authSnapshot.data!) {
            // Not authenticated → go to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/auth');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Authenticated → check role
          return FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, roleSnapshot) {
              if (!roleSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.data != 'admin') {
                // Not admin → redirect to home or error
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed('/');
                });
                return const Scaffold(
                  body: Center(child: Text('Access denied: Admins only')),
                );
              }

              // Authenticated + admin → show page
              return builder(context);
            },
          );
        },
      ),
    );
  }

  // Protected routes → check only authentication
  if (protectedRoutesList.contains(name)) {
    return MaterialPageRoute(
      builder: (context) => FutureBuilder<bool>(
        future: _isAuthenticated(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.data!) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/auth');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return builder(context);
        },
      ),
    );
  }

  // Default → treat as unprotected
  return MaterialPageRoute(builder: builder);
}

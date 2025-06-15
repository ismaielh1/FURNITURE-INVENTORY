import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:furniture_inventory/screens/categories_screen.dart';
import 'package:furniture_inventory/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to auth changes and rebuilds the UI automatically.
    // This is the most reliable way to handle auth state.
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While waiting for the first auth event, show a loader.
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // If user is logged in, show the main screen.
          // We wrap it in a FutureBuilder to set up the session correctly.
          return FutureBuilder(
            future: _setupUserSession(context, session),
            builder: (context, setupSnapshot) {
              // Once the session is set up, show the CategoriesScreen.
              // The CategoriesScreen will handle its own data loading.
              return const CategoriesScreen();
            },
          );
        } else {
          // If user is not logged in, show the login screen.
          return const LoginScreen();
        }
      },
    );
  }

  // This helper function sets up the provider's state without navigating.
  Future<void> _setupUserSession(
      BuildContext context, Session session) async {
    final provider = context.read<InventoryProvider>();
    final userRole =
        session.user.userMetadata?['role'] ?? 'worker';
    provider.isAdmin =
        (userRole == 'admin' || userRole == 'super_admin');
  }
}

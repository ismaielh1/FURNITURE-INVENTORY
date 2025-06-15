import 'package:flutter/material.dart';
import 'package:furniture_inventory/core/env/env.dart'; // <-- 1. Import the new Env class
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:furniture_inventory/screens/auth_check_screen.dart';
import 'package:furniture_inventory/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase with the secure keys from Env class
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => InventoryProvider(),
      child: const FurnitureInventoryApp(),
    ),
  );
}

class FurnitureInventoryApp extends StatelessWidget {
  const FurnitureInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The rest of this file is exactly the same as your old file
    return MaterialApp(
      title: 'جرد المفروشات',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          surfaceTintColor: Colors.white,
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
          bodyLarge: TextStyle(color: Color(0xFF616161)),
          titleMedium: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthCheckScreen(),
    );
  }
}

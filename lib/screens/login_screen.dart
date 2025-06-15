import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // --- UPDATED LOGIC TO HANDLE 3 ROLES ---
    String username = _userController.text.trim().toLowerCase();
    String email;
    const String appDomain = "inventoryapp.com";

    // Convert username to a specific email based on the role
    if (username == 'ismaiel') {
      // Your personal username
      email = 'superadmin@$appDomain';
    } else if (username == 'مدير') {
      // The manager's username
      email = 'admin@$appDomain';
    } else if (username == 'عامل') {
      // The worker's username
      email = 'worker@$appDomain';
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('اسم المستخدم غير صالح'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }
    // --- END OF NEW LOGIC ---

    try {
      final provider = context.read<InventoryProvider>();
      await provider.login(
        email,
        _passController.text,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ غير متوقع'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // The build method remains exactly the same as before
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 60,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جرد المستودع',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _userController,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                            
                          ),
                          validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? 'الرجاء إدخال اسم المستخدم'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passController,
                          textAlign: TextAlign.right,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                          ),
                          validator: (value) => (value == null ||
                                  value.length < 6)
                              ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
                              : null,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(
                                double.infinity,
                                50,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('دخول'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

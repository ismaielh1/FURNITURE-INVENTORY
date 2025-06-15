import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:provider/provider.dart';
import '../screens/changelog_screen.dart';
import '../screens/settings_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ هذا هو الكود الذي تم إضافته لتحديد العنوان الصحيح ▼▼▼
    final provider = context.watch<InventoryProvider>();
    final userRole = provider
        .supabase.auth.currentUser?.userMetadata?['role'];

    String drawerTitle = 'لوحة التحكم'; // عنوان افتراضي
    if (userRole == 'super_admin') {
      drawerTitle = 'لوحة تحكم السوبر أدمن';
    } else if (userRole == 'admin') {
      drawerTitle = 'لوحة تحكم المدير';
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              drawerTitle, // استخدام العنوان المتغير هنا
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('سجل التعديلات العام'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const ChangelogScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.red.shade700,
            ),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await context.read<InventoryProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}

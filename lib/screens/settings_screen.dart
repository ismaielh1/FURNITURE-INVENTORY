import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _adminPassController = TextEditingController();
  final _workerPassController = TextEditingController();
  final _myPassController = TextEditingController();

  bool _isSavingAdmin = false;
  bool _isSavingWorker = false;
  bool _isSavingMine = false;

  @override
  void dispose() {
    _adminPassController.dispose();
    _workerPassController.dispose();
    _myPassController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(
      String role, TextEditingController controller) async {
    if (controller.text.isEmpty || controller.text.length < 6) {
      _showMessage('يجب أن تكون كلمة المرور 6 أحرف على الأقل',
          isError: true);
      return;
    }

    if (role == 'admin') setState(() => _isSavingAdmin = true);
    if (role == 'worker') setState(() => _isSavingWorker = true);
    if (role == 'my_password')
      setState(() => _isSavingMine = true);

    try {
      await context.read<InventoryProvider>().changeUserPassword(
          targetRole: role, newPassword: controller.text);

      _showMessage('تم تغيير كلمة المرور بنجاح');
      controller.clear();
    } catch (e) {
      _showMessage('فشلت العملية: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        if (role == 'admin')
          setState(() => _isSavingAdmin = false);
        if (role == 'worker')
          setState(() => _isSavingWorker = false);
        if (role == 'my_password')
          setState(() => _isSavingMine = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // نحصل على دور المستخدم الحالي من البروفايدر
    final provider = context.read<InventoryProvider>();
    final currentUserRole = provider
        .supabase.auth.currentUser?.userMetadata?['role'];

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // واجهة السوبر أدمن
          if (currentUserRole == 'super_admin') ...[
            _buildPasswordCard(
              context: context,
              title: 'تغيير كلمة مرور المدير',
              controller: _adminPassController,
              onSave: () =>
                  _changePassword('admin', _adminPassController),
              isSaving: _isSavingAdmin,
            ),
            _buildPasswordCard(
              context: context,
              title: 'تغيير كلمة مرور العامل',
              controller: _workerPassController,
              onSave: () => _changePassword(
                  'worker', _workerPassController),
              isSaving: _isSavingWorker,
            ),
          ],
          // واجهة المدير
          if (currentUserRole == 'admin') ...[
            _buildPasswordCard(
              context: context,
              title: 'تغيير كلمة المرور الخاصة بي',
              controller: _myPassController,
              onSave: () => _changePassword(
                  'my_password', _myPassController),
              isSaving: _isSavingMine,
            ),
            _buildPasswordCard(
              context: context,
              title: 'تغيير كلمة مرور العامل',
              controller: _workerPassController,
              onSave: () => _changePassword(
                  'worker', _workerPassController),
              isSaving: _isSavingWorker,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPasswordCard({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
    required bool isSaving,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                    : const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

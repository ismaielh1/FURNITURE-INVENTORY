import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:furniture_inventory/utils/icon_helper.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;
  final String? parentCategoryId;

  const AddEditCategoryScreen({
    Key? key,
    this.category,
    this.parentCategoryId,
  }) : super(key: key);

  @override
  _AddEditCategoryScreenState createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState
    extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _categoryName;
  late IconData _selectedIcon;
  String? _selectedParentId;
  bool _isSaving = false;

  final List<IconData> _availableIcons =
      IconHelper.iconMap.values.toList();

  @override
  void initState() {
    super.initState();
    _categoryName = widget.category?.name ?? '';
    _selectedIcon = widget.category?.icon ?? _availableIcons[0];
    _selectedParentId =
        widget.category?.parentId ?? widget.parentCategoryId;
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final categoryToSave = Category(
        id: widget.category?.id ?? '',
        name: _categoryName,
        icon: _selectedIcon,
        parentId: _selectedParentId,
      );

      final provider = context.read<InventoryProvider>();
      bool success = false;
      if (widget.category == null) {
        success = await provider.addCategory(categoryToSave);
      } else {
        success = await provider.updateCategory(categoryToSave);
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(provider.errorMessage ??
                        'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        context.read<InventoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null
              ? 'إضافة قسم جديد'
              : 'تعديل القسم',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _categoryName,
                decoration: const InputDecoration(
                  labelText: 'اسم القسم',
                ),
                validator: (v) =>
                    v!.isEmpty ? 'الرجاء إدخال اسم.' : null,
                onSaved: (v) => _categoryName = v!,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String?>(
                value: _selectedParentId,
                decoration: const InputDecoration(
                  labelText: 'القسم الأب (اختياري)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('لا يوجد (قسم رئيسي)'),
                  ),
                  ...categories
                      .where((c) => c.id != widget.category?.id)
                      .map((Category category) {
                    return DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  setState(() => _selectedParentId = newValue);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'اختر أيقونة:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _availableIcons.map((icon) {
                    final isSelected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIcon = icon),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : Colors.black.withOpacity(0.05),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : Colors.black54,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveForm,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('حفظ'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

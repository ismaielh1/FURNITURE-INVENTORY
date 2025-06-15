import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../screens/categories_screen.dart';
import '../screens/products_screen.dart';

class CategoryGridItem extends StatelessWidget {
  final Category category;

  const CategoryGridItem({Key? key, required this.category})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();

    return Card(
      shape: Theme.of(context).cardTheme.shape,
      clipBehavior: Theme.of(context).cardTheme.clipBehavior,
      elevation: Theme.of(context).cardTheme.elevation,
      child: InkWell(
        onLongPress: provider.isAdmin
            ? () {
                _showDeleteConfirmation(
                  context,
                  provider,
                  category,
                );
              }
            : null,
        onTap: () {
          final subCategories = provider.categories
              .where((c) => c.parentId == category.id)
              .toList();

          if (subCategories.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => CategoriesScreen(
                  parentId: category.id,
                  parentName: category.name,
                ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) =>
                    ProductsScreen(category: category),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  category.icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    InventoryProvider provider,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف قسم "${category.name}"؟ سيتم حذف جميع الأقسام الفرعية والمنتجات الموجودة بداخله أيضًا.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.deleteCategory(category);
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../screens/add_edit_product_screen.dart';
import '../screens/changelog_screen.dart';
import 'quantity_stepper.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  const ProductListItem({Key? key, required this.product})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();

    return Dismissible(
      key: ValueKey(product.id),
      direction: provider.isAdmin
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text("تأكيد الحذف"),
              content: Text(
                "هل أنت متأكد من رغبتك في حذف منتج \"${product.name}\"؟",
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("إلغاء"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    "حذف",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          await provider.deleteProduct(product);
          return true; // Return true to allow dismissal
        }
        return false; // Return false to prevent dismissal
      },
      onDismissed: (direction) {
        // The logic is now handled in confirmDismiss, but we can show a snackbar here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف "${product.name}"')),
        );
      },
      child: Card(
        child: InkWell(
          onTap: provider.isAdmin
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) =>
                          ChangelogScreen(product: product),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () {
                    if (product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(10),
                          child: InteractiveViewer(
                            panEnabled: false,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(12),
                              child:
                                  _buildImage(product.imageUrl),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImage(product.imageUrl),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: product.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Consumer<InventoryProvider>(
                        builder: (context, prov, child) {
                          // Find the latest version of the product from the provider list
                          final p = prov.products.firstWhere(
                            (item) => item.id == product.id,
                            orElse: () =>
                                product, // Fallback to the initial product data
                          );
                          if (prov.isAdmin) {
                            return QuantityStepper(
                              quantity: p.quantity,
                              onConfirm: (newQuantity) =>
                                  prov.updateQuantity(
                                p,
                                newQuantity,
                              ),
                            );
                          } else {
                            return Chip(
                              avatar: const Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                              ),
                              label: Text(
                                'الكمية: ${p.quantity}',
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (provider.isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => AddEditProductScreen(
                            product: product,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        alignment: Alignment.center,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
        ),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
          ),
        ),
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
          ),
        ),
      );
    }
  }
}

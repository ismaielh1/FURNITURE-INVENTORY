import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../widgets/empty_state_widget.dart';

class ChangelogScreen extends StatelessWidget {
  final Product? product;
  const ChangelogScreen({Key? key, this.product})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final logs = product == null
            ? provider.logs
            : provider.logs
                .where((log) => log.productId == product!.id)
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              product == null
                  ? 'سجل التعديلات العام'
                  : 'سجل: ${product!.name}',
            ),
          ),
          body: logs.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.history_toggle_off,
                  message: 'لا توجد تعديلات مسجلة',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (ctx, index) {
                    final log = logs[index];
                    final isDeletion =
                        log.changeType == 'حذف منتج';
                    final isCreation =
                        log.changeType == 'إنشاء منتج';

                    return Card(
                      elevation: 1,
                      color: isDeletion
                          ? Colors.red.withOpacity(0.05)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDeletion
                            ? BorderSide(
                                color: Colors.red.shade200,
                                width: 1)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getColorForChangeType(
                                  log.changeType, context),
                          foregroundColor: Colors.white,
                          child: Icon(_getIconForChangeType(
                              log.changeType)),
                        ),
                        title: Text(
                          product != null
                              ? log.changeType
                              : log.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          product == null
                              ? log.changeType
                              : '${log.timestamp.toLocal().hour}:${log.timestamp.toLocal().minute.toString().padLeft(2, '0')} - ${log.timestamp.toLocal().day}/${log.timestamp.toLocal().month}',
                        ),
                        trailing: (isCreation || isDeletion)
                            ? SizedBox(
                                width: 120,
                                child: Text(
                                  isDeletion
                                      ? log.oldValue
                                      : log.newValue,
                                  style: TextStyle(
                                      color: isDeletion
                                          ? Colors.red.shade700
                                          : Colors.grey.shade700,
                                      fontSize: 12),
                                  textAlign: TextAlign.end,
                                ),
                              )
                            // ▼▼▼ تم توحيد التنسيق لجميع التغييرات هنا ▼▼▼
                            : RichText(
                                textDirection: TextDirection.rtl,
                                text: TextSpan(
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: log
                                          .newValue, // القيمة الجديدة (دائمًا يمينًا)
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '  →  ',
                                      style: TextStyle(
                                          color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text: log
                                          .oldValue, // القيمة القديمة (دائمًا يسارًا)
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        decoration:
                                            TextDecoration
                                                .lineThrough,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  IconData _getIconForChangeType(String changeType) {
    switch (changeType) {
      case 'الكمية':
        return Icons.inventory_2_outlined;
      case 'الاسم':
        return Icons.edit_outlined;
      case 'اللون':
        return Icons.color_lens_outlined;
      case 'الصورة':
        return Icons.image_outlined;
      case 'إنشاء منتج':
        return Icons.add_circle_outline;
      case 'حذف منتج':
        return Icons.remove_circle_outline;
      default:
        return Icons.history;
    }
  }

  Color _getColorForChangeType(
      String changeType, BuildContext context) {
    switch (changeType) {
      case 'حذف منتج':
        return Colors.red.shade700;
      case 'إنشاء منتج':
        return Colors.green.shade700;
      case 'الكمية':
        return Colors.orange.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

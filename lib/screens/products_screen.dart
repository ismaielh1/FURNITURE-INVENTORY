import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:furniture_inventory/widgets/error_state_widget.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/product_list_item.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatelessWidget {
  final Category category;

  const ProductsScreen({Key? key, required this.category})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final products = provider.products
            .where((p) => p.categoryId == category.id)
            .toList();

        Widget buildBody() {
          if (provider.isLoading && products.isEmpty) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null &&
              products.isEmpty) {
            return ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.loadData(),
            );
          }
          if (products.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off,
              message: 'لا توجد منتجات في هذا القسم',
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: products.length,
            itemBuilder: (ctx, i) =>
                ProductListItem(product: products[i]),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(category.name)),
          body: RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: buildBody(),
          ),
          floatingActionButton: provider.isAdmin
              ? FloatingActionButton(
                  heroTag: 'products_fab_${category.id}',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => AddEditProductScreen(
                          categoryId: category.id,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}

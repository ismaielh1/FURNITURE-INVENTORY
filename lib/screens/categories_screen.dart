import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:furniture_inventory/screens/update_screen.dart';
import 'package:furniture_inventory/widgets/admin_drawer.dart';
import 'package:furniture_inventory/widgets/category_grid_item.dart';
import 'package:furniture_inventory/widgets/empty_state_widget.dart';
import 'package:furniture_inventory/widgets/error_state_widget.dart';
import 'package:provider/provider.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String? parentId;
  final String? parentName;

  const CategoriesScreen({
    Key? key,
    this.parentId,
    this.parentName,
  }) : super(key: key);

  @override
  State<CategoriesScreen> createState() =>
      _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<InventoryProvider>();
        final session = provider.supabase.auth.currentSession;

        if (session != null) {
          final userRole =
              session.user.userMetadata?['role'] ?? 'worker';
          provider.isAdmin =
              (userRole == 'admin' || userRole == 'super_admin');
        }

        if (provider.categories.isEmpty) {
          provider.loadData().then((_) {
            if (mounted &&
                widget.parentId == null &&
                provider.isUpdateAvailable &&
                provider.forceUpdate) {
              _showForceUpdateDialog();
            }
          });
        }
      }
    });
  }

  void _showForceUpdateDialog() {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('تحديث إجباري'),
            content: Text(
              'يتوفر إصدار جديد ومهم من التطبيق (${provider.latestVersion}). يجب عليك التحديث للمتابعة.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('التحديث الآن'),
                onPressed: () {
                  Navigator.of(dialogContext).pushReplacement(
                    MaterialPageRoute(
                      builder: (ctx) => const UpdateScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    // This is the main loading indicator for when the app starts.
    if (widget.parentId == null &&
        provider.isLoading &&
        provider.categories.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    // The logic for the stuck loader is removed. The dialog will now show over the built UI.

    final categories = provider.categories
        .where((c) => c.parentId == widget.parentId)
        .toList();

    Widget buildBody() {
      if (provider.errorMessage != null && categories.isEmpty) {
        return ErrorStateWidget(
          message: provider.errorMessage!,
          onRetry: () =>
              context.read<InventoryProvider>().loadData(),
        );
      }
      if (categories.isEmpty && !provider.isLoading) {
        return const EmptyStateWidget(
          icon: Icons.category_outlined,
          message: 'لا توجد أقسام هنا',
        );
      }
      return GridView.builder(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16.0),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (ctx, i) =>
            CategoryGridItem(category: categories[i]),
      );
    }

    return Scaffold(
      drawer: provider.isAdmin && widget.parentId == null
          ? const AdminDrawer()
          : null,
      appBar: AppBar(
        title: Text(widget.parentName ?? 'الأقسام الرئيسية'),
        actions: [
          if (!provider.isAdmin)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () async {
                await context.read<InventoryProvider>().logout();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (provider.isUpdateAvailable &&
              !provider.forceUpdate &&
              widget.parentId == null)
            MaterialBanner(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              content: Text(
                  'يوجد تحديث جديد! الإصدار ${provider.latestVersion} متاح الآن.'),
              actions: [
                TextButton(
                    child: const Text('عرض التفاصيل'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const UpdateScreen(),
                        ),
                      );
                    }),
              ],
              backgroundColor: Colors.amber.shade100,
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<InventoryProvider>().loadData(),
              child: buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: provider.isAdmin
          ? FloatingActionButton(
              heroTag: widget.parentId ?? 'categories_fab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AddEditCategoryScreen(
                        parentCategoryId: widget.parentId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

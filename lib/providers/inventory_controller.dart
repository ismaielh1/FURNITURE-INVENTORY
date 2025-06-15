import 'dart:io';
import 'package:flutter/material.dart';
import 'package:furniture_inventory/utils/color_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/log_entry.dart';

class InventoryProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;
  bool isAdmin = false;
  List<Category> _categories = [];
  List<Product> _products = [];
  List<LogEntry> _changeLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _latestVersion;
  String? _updateNotes;
  bool _isUpdateAvailable = false;
  String? _downloadUrl;
  bool _forceUpdate = false;

  // --- Getters ---
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<LogEntry> get logs => _changeLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get latestVersion => _latestVersion;
  String? get updateNotes => _updateNotes;
  bool get isUpdateAvailable => _isUpdateAvailable;
  String? get downloadUrl => _downloadUrl;
  bool get forceUpdate => _forceUpdate;

  // --- Auth & Password Management ---
  Future<void> login(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    isAdmin = false;
    _categories = [];
    _products = [];
    _changeLogs = [];
    notifyListeners();
  }

  Future<void> changeUserPassword(
      {required String targetRole,
      required String newPassword}) async {
    String targetEmail;
    final String? callerRole =
        supabase.auth.currentUser?.userMetadata?['role'];

    if (targetRole == 'my_password') {
      if (callerRole == 'admin') {
        targetEmail = 'admin@inventoryapp.com';
      } else {
        throw Exception(
            "فقط المدير يمكنه تغيير كلمة المرور الخاصة به.");
      }
    } else if (targetRole == 'admin') {
      targetEmail = 'admin@inventoryapp.com';
    } else if (targetRole == 'worker') {
      targetEmail = 'worker@inventoryapp.com';
    } else {
      throw Exception('الدور المستهدف غير صالح.');
    }

    if (targetEmail == 'superadmin@inventoryapp.com') {
      throw Exception(
          "لا يمكن تغيير كلمة مرور السوبر أدمن من داخل التطبيق.");
    }

    try {
      final response = await supabase.functions.invoke(
        'set-user-password',
        body: {
          'target_email': targetEmail,
          'new_password': newPassword,
        },
      );

      if (response.status != 200) {
        final errorBody = response.data as Map<String, dynamic>?;
        final errorMessage = errorBody?['error'] ??
            'حدث خطأ غير معروف من الدالة السحابية.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error invoking edge function: $e');
      rethrow;
    }
  }

  // --- Data Loading & Update Check ---
  Future<void> loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([
        _fetchCategories(),
        _fetchProducts(),
        _fetchLogs(),
        checkForUpdate(),
      ]);
    } catch (e) {
      _errorMessage =
          'فشل تحميل البيانات. تحقق من اتصالك بالإنترنت.';
      print('Load Data Error: $e');
    } finally {
      if (ChangeNotifier.debugAssertNotDisposed(this)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchCategories() async {
    final data = await supabase
        .from('categories')
        .select()
        .order('created_at');
    _categories =
        (data).map((json) => Category.fromJson(json)).toList();
  }

  Future<void> _fetchProducts() async {
    final data = await supabase
        .from('products')
        .select()
        .order('created_at');
    _products =
        (data).map((json) => Product.fromJson(json)).toList();
  }

  Future<void> _fetchLogs() async {
    final data = await supabase
        .from('logs')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    _changeLogs =
        (data).map((json) => LogEntry.fromJson(json)).toList();
  }

  // ▼▼▼ هذه هي الدالة التي تم تعديلها ▼▼▼
  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final data =
          await supabase.from('app_metadata').select().single();

      // يقوم بحذف أي مسافات زائدة من الرقم القادم من قاعدة البيانات
      _latestVersion =
          (data['latest_version'] as String?)?.trim();

      // أسطر الطباعة للمساعدة في كشف الخطأ
      print("--- Update Check ---");
      print("Current App Version: '$currentVersion'");
      print("Latest Version from DB: '$_latestVersion'");
      print(
          "Are they equal? ${_latestVersion == currentVersion}");
      print("--------------------");

      if (_latestVersion != null &&
          _latestVersion != currentVersion) {
        _isUpdateAvailable = true;
      } else {
        _isUpdateAvailable = false;
        _forceUpdate = false;
      }
    } catch (e) {
      print("Failed to check for updates: $e");
      _isUpdateAvailable = false;
      _forceUpdate = false;
    }
  }

  // --- Your Original CRUD Functions ---
  Future<void> _logChange(
      {required String productId,
      required String productName,
      required String changeType,
      required String oldValue,
      required String newValue}) async {
    final logData = {
      'product_id': productId,
      'product_name': productName,
      'change_type': changeType,
      'old_value': oldValue,
      'new_value': newValue,
    };
    try {
      final insertedData =
          await supabase.from('logs').insert(logData).select();
      if (insertedData.isNotEmpty) {
        _changeLogs.insert(
            0, LogEntry.fromJson(insertedData.first));
        notifyListeners();
      }
    } catch (e) {
      print("Failed to write log: $e");
    }
  }

  Future<bool> _runWriteOperation(
      Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
      await loadData(); // Reload all data on success
      return true;
    } catch (e) {
      _errorMessage = 'فشلت العملية: ${e.toString()}';
      print('Write Operation Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity(
      Product product, int newQuantity) async {
    final oldQuantity = product.quantity;
    product.quantity = newQuantity;
    notifyListeners();
    await _logChange(
      productId: product.id,
      productName: product.name,
      changeType: 'الكمية',
      oldValue: oldQuantity.toString(),
      newValue: newQuantity.toString(),
    );
    try {
      await supabase.from('products').update(
          {'quantity': newQuantity}).eq('id', product.id);
    } catch (e) {
      product.quantity = oldQuantity; // Revert on error
      _errorMessage = 'فشل تحديث الكمية: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product p, File? imageFile) async {
    return _runWriteOperation(() async {
      final newProductData = p.toJson(withId: false)
        ..remove('image_url');
      final insertedData = await supabase
          .from('products')
          .insert(newProductData)
          .select();
      if (insertedData.isEmpty)
        throw Exception("Failed to create product");

      final newProduct = Product.fromJson(insertedData.first);
      if (imageFile != null) {
        final fileName =
            '${newProduct.id}.${imageFile.path.split('.').last}';
        await supabase.storage.from('product-images').upload(
            fileName, imageFile,
            fileOptions: const FileOptions(upsert: true));
        final publicUrl = supabase.storage
            .from('product-images')
            .getPublicUrl(fileName);
        final imageUrlWithCacheBuster =
            '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        await supabase
            .from('products')
            .update({'image_url': imageUrlWithCacheBuster}).eq(
                'id', newProduct.id);
      }
      await _logChange(
          productId: newProduct.id,
          productName: newProduct.name,
          changeType: "إنشاء منتج",
          oldValue: "-",
          newValue: "الكمية: ${newProduct.quantity}");
    });
  }

  Future<bool> updateProduct(Product p, File? imageFile) async {
    return _runWriteOperation(() async {
      final oldProduct =
          _products.firstWhere((prod) => prod.id == p.id);
      final Map<String, dynamic> updateData = {};
      if (p.name != oldProduct.name) {
        updateData['name'] = p.name;
        await _logChange(
            productId: p.id,
            productName: oldProduct.name,
            changeType: 'الاسم',
            oldValue: oldProduct.name,
            newValue: p.name);
      }
      if (p.quantity != oldProduct.quantity) {
        updateData['quantity'] = p.quantity;
        await _logChange(
            productId: p.id,
            productName: p.name,
            changeType: 'الكمية',
            oldValue: oldProduct.quantity.toString(),
            newValue: p.quantity.toString());
      }
      if (p.color.value != oldProduct.color.value) {
        updateData['color_value'] = p.color.value;
        await _logChange(
            productId: p.id,
            productName: p.name,
            changeType: 'اللون',
            oldValue: ColorHelper.getColorName(oldProduct.color),
            newValue: ColorHelper.getColorName(p.color));
      }
      if (imageFile != null) {
        final fileName =
            '${p.id}.${imageFile.path.split('.').last}';
        await supabase.storage.from('product-images').upload(
            fileName, imageFile,
            fileOptions: const FileOptions(upsert: true));
        final publicUrl = supabase.storage
            .from('product-images')
            .getPublicUrl(fileName);
        final newImageUrlWithCacheBuster =
            '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        updateData['image_url'] = newImageUrlWithCacheBuster;
        await _logChange(
            productId: p.id,
            productName: p.name,
            changeType: 'الصورة',
            oldValue: "قديمة",
            newValue: "جديدة");
      }
      if (updateData.isNotEmpty) {
        await supabase
            .from('products')
            .update(updateData)
            .eq('id', p.id);
      }
    });
  }

  Future<bool> deleteProduct(Product product) async {
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();
    await _logChange(
        productId: product.id,
        productName: product.name,
        changeType: 'حذف منتج',
        oldValue: 'الكمية كانت: ${product.quantity}',
        newValue: 'تم الحذف');
    return _runWriteOperation(() async {
      if (product.imageUrl != null &&
          product.imageUrl!.isNotEmpty) {
        try {
          final path =
              Uri.parse(product.imageUrl!).pathSegments.last;
          await supabase.storage
              .from('product-images')
              .remove([path]);
        } catch (e) {
          print('Could not delete image from storage: $e');
        }
      }
      await supabase
          .from('products')
          .delete()
          .eq('id', product.id);
    });
  }

  Future<bool> addCategory(Category c) async {
    return _runWriteOperation(() async {
      await supabase
          .from('categories')
          .insert(c.toJson(withId: false));
    });
  }

  Future<bool> updateCategory(Category c) async {
    return _runWriteOperation(() async {
      await supabase
          .from('categories')
          .update(c.toJson(withId: false))
          .eq('id', c.id);
    });
  }

  Future<bool> deleteCategory(Category category) async {
    return _runWriteOperation(() async {
      await supabase
          .from('categories')
          .delete()
          .eq('id', category.id);
    });
  }
}

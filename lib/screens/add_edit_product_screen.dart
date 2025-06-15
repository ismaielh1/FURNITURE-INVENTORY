import 'dart:io';
import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/product.dart';
import '../widgets/image_picker_widget.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  final String? categoryId;

  const AddEditProductScreen({
    Key? key,
    this.product,
    this.categoryId,
  }) : super(key: key);

  @override
  _AddEditProductScreenState createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState
    extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _quantity;
  File? _imageFile;
  late Color _selectedColor;
  bool _isSaving = false;
  final List<Color> _availableColors = const [
    Colors.black,
    Colors.white,
    Colors.grey,
    Colors.red,
    Colors.blue,
    Colors.green,
    Color(0xFF8D6E63),
    Colors.yellow,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _quantity = widget.product?.quantity ?? 0;
    _selectedColor =
        widget.product?.color ?? _availableColors[0];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg');

    final compressedFile =
        await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      targetPath,
      quality: 70,
    );

    if (compressedFile != null) {
      setState(() => _imageFile = File(compressedFile.path));
    }
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final product = Product(
        id: widget.product?.id ?? '',
        categoryId:
            widget.product?.categoryId ?? widget.categoryId!,
        name: _name,
        quantity: _quantity,
        imageUrl: widget.product?.imageUrl,
        color: _selectedColor,
      );

      final provider = context.read<InventoryProvider>();
      bool success = false;
      if (widget.product == null) {
        success = await provider.addProduct(product, _imageFile);
      } else {
        success =
            await provider.updateProduct(product, _imageFile);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'إضافة منتج' : 'تعديل منتج',
        ),
      ),
      body: IgnorePointer(
        ignoring: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ImagePickerWidget(
                  imageFile: _imageFile,
                  existingImageUrl: widget.product?.imageUrl,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج (اختياري)',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: null,
                  onSaved: (v) => _name = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'الكمية (اختياري)',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: null,
                  onSaved: (v) =>
                      _quantity = int.tryParse(v ?? '') ?? 0,
                ),
                const SizedBox(height: 24),
                Text(
                  'اختر اللون:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableColors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final color = _availableColors[index];
                      final isSelected =
                          _selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () => setState(
                          () => _selectedColor = color,
                        ),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black45,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color:
                                      color.computeLuminance() >
                                              0.5
                                          ? Colors.black
                                          : Colors.white,
                                )
                              : null,
                        ),
                      );
                    },
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
                      : const Text('حفظ المنتج'),
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
      ),
    );
  }
}

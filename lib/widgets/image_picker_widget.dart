import 'dart:io';
import 'package:flutter/material.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final String? existingImageUrl;
  final VoidCallback onTap;
  const ImagePickerWidget({
    Key? key,
    this.imageFile,
    this.existingImageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageContent;
    if (imageFile != null) {
      imageContent = Image.file(imageFile!, fit: BoxFit.cover);
    } else if (existingImageUrl != null &&
        existingImageUrl!.isNotEmpty) {
      imageContent = _buildImage(existingImageUrl!);
    } else {
      imageContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.add_a_photo_outlined,
            size: 40,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text('اختيار صورة المنتج'),
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageContent,
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
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
        errorBuilder: (c, e, s) => Container(
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

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Service to handle receipt images for PDF embedding
class ReceiptImageHandler {
  /// Maximum image width for PDF embedding
  static const int maxImageWidth = 800;

  /// Maximum image height for PDF embedding
  static const int maxImageHeight = 1200;

  /// JPEG quality for compression (0-100)
  static const int jpegQuality = 85;

  /// Load and process receipt image for PDF
  static Future<Uint8List?> loadAndProcessReceiptImage(
    String? imagePath, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    try {
      // Get full image path
      final fullPath = await _getFullImagePath(imagePath);
      final file = File(fullPath);

      if (!await file.exists()) {
        debugPrint('Receipt image not found: $fullPath');
        return null;
      }

      // Read image bytes
      final bytes = await file.readAsBytes();

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('Failed to decode image: $fullPath');
        return null;
      }

      // Resize if needed
      final resizedImage = _resizeImage(
        image,
        maxWidth: maxWidth ?? maxImageWidth,
        maxHeight: maxHeight ?? maxImageHeight,
      );

      // Compress to JPEG
      final compressed = img.encodeJpg(
        resizedImage,
        quality: quality ?? jpegQuality,
      );

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error processing receipt image: $e');
      return null;
    }
  }

  /// Get full image path from relative path
  static Future<String> _getFullImagePath(String relativePath) async {
    if (relativePath.startsWith('/')) {
      return relativePath; // Already full path
    }

    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$relativePath';
  }

  /// Resize image maintaining aspect ratio
  static img.Image _resizeImage(
    img.Image image, {
    required int maxWidth,
    required int maxHeight,
  }) {
    // Check if resizing is needed
    if (image.width <= maxWidth && image.height <= maxHeight) {
      return image;
    }

    // Calculate new dimensions maintaining aspect ratio
    double ratio = image.width / image.height;
    int newWidth = maxWidth;
    int newHeight = (newWidth / ratio).round();

    if (newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (newHeight * ratio).round();
    }

    // Resize using high-quality algorithm
    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Generate thumbnail from receipt image
  static Future<Uint8List?> generateThumbnail(
    String? imagePath, {
    int size = 150,
  }) async {
    return loadAndProcessReceiptImage(
      imagePath,
      maxWidth: size,
      maxHeight: size,
      quality: 70,
    );
  }

  /// Get receipt image file size
  static Future<int?> getImageFileSize(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    try {
      final fullPath = await _getFullImagePath(imagePath);
      final file = File(fullPath);

      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Error getting image file size: $e');
    }

    return null;
  }

  /// Check if receipt image exists
  static Future<bool> receiptImageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final fullPath = await _getFullImagePath(imagePath);
      final file = File(fullPath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking receipt image: $e');
      return false;
    }
  }

  /// Get image dimensions without loading full image
  static Future<Size?> getImageDimensions(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    try {
      final fullPath = await _getFullImagePath(imagePath);
      final file = File(fullPath);

      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        return Size(image.width.toDouble(), image.height.toDouble());
      }
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
    }

    return null;
  }

  /// Load multiple receipt images with error handling
  static Future<Map<String, Uint8List>> loadMultipleReceipts(
    List<String> imagePaths, {
    void Function(int loaded, int total)? onProgress,
  }) async {
    final Map<String, Uint8List> images = {};
    int loaded = 0;

    for (final path in imagePaths) {
      final imageData = await loadAndProcessReceiptImage(path);
      if (imageData != null) {
        images[path] = imageData;
      }

      loaded++;
      onProgress?.call(loaded, imagePaths.length);
    }

    return images;
  }

  /// Calculate optimal image size for PDF
  static Size calculateOptimalSize(
    Size originalSize, {
    double maxWidthInPoints = 500,
    double maxHeightInPoints = 700,
  }) {
    final ratio = originalSize.width / originalSize.height;
    double width = maxWidthInPoints;
    double height = width / ratio;

    if (height > maxHeightInPoints) {
      height = maxHeightInPoints;
      width = height * ratio;
    }

    return Size(width, height);
  }

  /// Get receipt image metadata
  static Future<Map<String, dynamic>?> getImageMetadata(
    String? imagePath,
  ) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    try {
      final exists = await receiptImageExists(imagePath);
      if (!exists) return null;

      final size = await getImageFileSize(imagePath);
      final dimensions = await getImageDimensions(imagePath);

      return {
        'path': imagePath,
        'exists': exists,
        'size': size,
        'width': dimensions?.width,
        'height': dimensions?.height,
      };
    } catch (e) {
      debugPrint('Error getting image metadata: $e');
      return null;
    }
  }
}

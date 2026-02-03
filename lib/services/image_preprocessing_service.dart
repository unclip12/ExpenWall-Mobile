import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for preprocessing images to improve OCR accuracy
/// Applies various image enhancement techniques before OCR processing
class ImagePreprocessingService {
  /// Preprocess image for better OCR results
  /// Returns path to preprocessed image
  static Future<String> preprocessForOCR(
    String imagePath, {
    PreprocessingStrategy strategy = PreprocessingStrategy.auto,
  }) async {
    try {
      // Load original image
      final originalFile = File(imagePath);
      final bytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply preprocessing based on strategy
      img.Image processed;
      switch (strategy) {
        case PreprocessingStrategy.auto:
          processed = _autoPreprocess(image);
          break;
        case PreprocessingStrategy.receipt:
          processed = _receiptPreprocess(image);
          break;
        case PreprocessingStrategy.document:
          processed = _documentPreprocess(image);
          break;
        case PreprocessingStrategy.lowLight:
          processed = _lowLightPreprocess(image);
          break;
        case PreprocessingStrategy.aggressive:
          processed = _aggressivePreprocess(image);
          break;
      }

      // Save preprocessed image
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path,
        'preprocessed_$timestamp.jpg',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(processed, quality: 95));

      return outputPath;
    } catch (e) {
      print('Preprocessing error: $e');
      // Return original path if preprocessing fails
      return imagePath;
    }
  }

  /// Auto strategy - analyzes image and applies best preprocessing
  static img.Image _autoPreprocess(img.Image image) {
    // Analyze image characteristics
    final brightness = _calculateBrightness(image);
    final contrast = _calculateContrast(image);

    // Choose strategy based on analysis
    if (brightness < 80) {
      return _lowLightPreprocess(image);
    } else if (contrast < 50) {
      return _aggressivePreprocess(image);
    } else {
      return _receiptPreprocess(image);
    }
  }

  /// Receipt strategy - optimized for thermal paper receipts
  static img.Image _receiptPreprocess(img.Image image) {
    img.Image processed = img.copyResize(
      image,
      width: image.width > 2000 ? 2000 : null,
    );

    // Convert to grayscale
    processed = img.grayscale(processed);

    // Enhance contrast
    processed = img.adjustColor(
      processed,
      contrast: 1.3,
      brightness: 1.1,
    );

    // Apply sharpening
    processed = img.convolution(
      processed,
      [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ],
      div: 1,
    );

    // Normalize histogram for better text clarity
    processed = _normalizeHistogram(processed);

    return processed;
  }

  /// Document strategy - for clean documents and invoices
  static img.Image _documentPreprocess(img.Image image) {
    img.Image processed = img.copyResize(
      image,
      width: image.width > 2500 ? 2500 : null,
    );

    // Convert to grayscale
    processed = img.grayscale(processed);

    // Mild contrast enhancement
    processed = img.adjustColor(
      processed,
      contrast: 1.2,
    );

    // Light sharpening
    processed = img.convolution(
      processed,
      [
        -1, -1, -1,
        -1, 9, -1,
        -1, -1, -1,
      ],
      div: 1,
    );

    return processed;
  }

  /// Low light strategy - for photos taken in poor lighting
  static img.Image _lowLightPreprocess(img.Image image) {
    img.Image processed = img.copyResize(
      image,
      width: image.width > 2000 ? 2000 : null,
    );

    // Convert to grayscale
    processed = img.grayscale(processed);

    // Strong brightness boost
    processed = img.adjustColor(
      processed,
      brightness: 1.4,
      contrast: 1.5,
    );

    // Histogram equalization for better light distribution
    processed = _equalizeHistogram(processed);

    // Aggressive sharpening
    processed = img.convolution(
      processed,
      [
        -1, -2, -1,
        -2, 13, -2,
        -1, -2, -1,
      ],
      div: 1,
    );

    return processed;
  }

  /// Aggressive strategy - maximum enhancement for difficult images
  static img.Image _aggressivePreprocess(img.Image image) {
    img.Image processed = img.copyResize(
      image,
      width: image.width > 2000 ? 2000 : null,
    );

    // Convert to grayscale
    processed = img.grayscale(processed);

    // Maximum contrast and brightness
    processed = img.adjustColor(
      processed,
      brightness: 1.3,
      contrast: 1.6,
    );

    // Histogram equalization
    processed = _equalizeHistogram(processed);

    // Adaptive thresholding for text clarity
    processed = _adaptiveThreshold(processed);

    // Strong sharpening
    processed = img.convolution(
      processed,
      [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ],
      div: 1,
    );

    return processed;
  }

  /// Calculate average brightness of image (0-255)
  static double _calculateBrightness(img.Image image) {
    int total = 0;
    int count = 0;

    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        total += img.getLuminance(pixel).toInt();
        count++;
      }
    }

    return count > 0 ? total / count : 128;
  }

  /// Calculate contrast of image (0-100)
  static double _calculateContrast(img.Image image) {
    List<int> luminance = [];

    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        luminance.add(img.getLuminance(pixel).toInt());
      }
    }

    if (luminance.isEmpty) return 50;

    luminance.sort();
    final median = luminance[luminance.length ~/ 2];
    
    int variance = 0;
    for (var l in luminance) {
      variance += (l - median) * (l - median);
    }
    variance ~/= luminance.length;

    return (variance / 65535 * 100).clamp(0, 100);
  }

  /// Normalize histogram for better contrast distribution
  static img.Image _normalizeHistogram(img.Image image) {
    // Find min and max pixel values
    int min = 255;
    int max = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final lum = img.getLuminance(pixel).toInt();
        if (lum < min) min = lum;
        if (lum > max) max = lum;
      }
    }

    // Normalize
    if (max > min) {
      final range = max - min;
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final lum = img.getLuminance(pixel).toInt();
          final normalized = ((lum - min) * 255 ~/ range).clamp(0, 255);
          image.setPixel(x, y, img.ColorRgb8(normalized, normalized, normalized));
        }
      }
    }

    return image;
  }

  /// Histogram equalization for better light distribution
  static img.Image _equalizeHistogram(img.Image image) {
    // Build histogram
    List<int> histogram = List.filled(256, 0);
    final totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final lum = img.getLuminance(pixel).toInt();
        histogram[lum]++;
      }
    }

    // Build cumulative distribution function
    List<int> cdf = List.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Normalize CDF
    final cdfMin = cdf.firstWhere((v) => v > 0);
    List<int> equalized = List.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      equalized[i] = 
          (((cdf[i] - cdfMin) * 255) / (totalPixels - cdfMin)).round().clamp(0, 255);
    }

    // Apply equalized values
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final lum = img.getLuminance(pixel).toInt();
        final newLum = equalized[lum];
        image.setPixel(x, y, img.ColorRgb8(newLum, newLum, newLum));
      }
    }

    return image;
  }

  /// Adaptive thresholding for text clarity
  static img.Image _adaptiveThreshold(img.Image image, {int windowSize = 15}) {
    final halfWindow = windowSize ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Calculate local mean
        int sum = 0;
        int count = 0;

        for (int dy = -halfWindow; dy <= halfWindow; dy++) {
          for (int dx = -halfWindow; dx <= halfWindow; dx++) {
            final nx = (x + dx).clamp(0, image.width - 1);
            final ny = (y + dy).clamp(0, image.height - 1);
            final pixel = image.getPixel(nx, ny);
            sum += img.getLuminance(pixel).toInt();
            count++;
          }
        }

        final localMean = sum ~/ count;
        final pixel = image.getPixel(x, y);
        final lum = img.getLuminance(pixel).toInt();

        // Apply threshold
        final newLum = lum > localMean ? 255 : 0;
        image.setPixel(x, y, img.ColorRgb8(newLum, newLum, newLum));
      }
    }

    return image;
  }

  /// Try multiple preprocessing strategies and return best result
  static Future<List<PreprocessedResult>> preprocessMultipleStrategies(
    String imagePath,
  ) async {
    final strategies = [
      PreprocessingStrategy.auto,
      PreprocessingStrategy.receipt,
      PreprocessingStrategy.lowLight,
      PreprocessingStrategy.aggressive,
    ];

    List<PreprocessedResult> results = [];

    for (var strategy in strategies) {
      try {
        final processedPath = await preprocessForOCR(
          imagePath,
          strategy: strategy,
        );
        results.add(PreprocessedResult(
          path: processedPath,
          strategy: strategy,
        ));
      } catch (e) {
        print('Strategy $strategy failed: $e');
      }
    }

    return results;
  }
}

/// Preprocessing strategies for different image types
enum PreprocessingStrategy {
  auto, // Auto-detect best strategy
  receipt, // Optimized for thermal receipts
  document, // For clean documents/invoices
  lowLight, // For poor lighting conditions
  aggressive, // Maximum enhancement
}

/// Result of preprocessing operation
class PreprocessedResult {
  final String path;
  final PreprocessingStrategy strategy;

  PreprocessedResult({
    required this.path,
    required this.strategy,
  });

  String get strategyName {
    switch (strategy) {
      case PreprocessingStrategy.auto:
        return 'Auto';
      case PreprocessingStrategy.receipt:
        return 'Receipt';
      case PreprocessingStrategy.document:
        return 'Document';
      case PreprocessingStrategy.lowLight:
        return 'Low Light';
      case PreprocessingStrategy.aggressive:
        return 'Aggressive';
    }
  }
}

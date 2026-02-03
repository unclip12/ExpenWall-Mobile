import 'dart:async';
import 'dart:io';
import 'receipt_ocr_service.dart';
import 'image_preprocessing_service.dart';

/// Enhanced OCR service that tries multiple preprocessing strategies
/// and returns the best result
class EnhancedReceiptOCRService {
  final ReceiptOCRService _baseOCRService = ReceiptOCRService();

  /// Scan receipt with multi-pass OCR
  /// Tries multiple preprocessing strategies and returns best result
  Future<EnhancedOCRResult> scanReceiptEnhanced(
    String imagePath, {
    bool useMultiPass = true,
  }) async {
    if (!useMultiPass) {
      // Single pass with original image
      final result = await _baseOCRService.scanReceipt(imagePath);
      return EnhancedOCRResult(
        receipt: result,
        strategy: 'Original',
        processingTime: Duration.zero,
        attemptsCount: 1,
      );
    }

    final startTime = DateTime.now();
    List<OCRAttempt> attempts = [];

    try {
      // First attempt: Original image
      final originalAttempt = await _attemptOCR(
        imagePath,
        'Original',
        null,
      );
      attempts.add(originalAttempt);

      // Generate preprocessed versions
      final preprocessedResults =
          await ImagePreprocessingService.preprocessMultipleStrategies(
        imagePath,
      );

      // Try OCR on each preprocessed version
      for (final preprocessed in preprocessedResults) {
        try {
          final attempt = await _attemptOCR(
            preprocessed.path,
            preprocessed.strategyName,
            preprocessed,
          );
          attempts.add(attempt);
        } catch (e) {
          print('OCR attempt failed for ${preprocessed.strategyName}: $e');
        }
      }

      // Clean up temporary preprocessed images
      for (final preprocessed in preprocessedResults) {
        try {
          await File(preprocessed.path).delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      // Select best result
      final bestAttempt = _selectBestResult(attempts);
      final processingTime = DateTime.now().difference(startTime);

      return EnhancedOCRResult(
        receipt: bestAttempt.receipt,
        strategy: bestAttempt.strategy,
        processingTime: processingTime,
        attemptsCount: attempts.length,
        allAttempts: attempts,
      );
    } catch (e) {
      print('Enhanced OCR error: $e');
      // Fallback to original image
      final result = await _baseOCRService.scanReceipt(imagePath);
      return EnhancedOCRResult(
        receipt: result,
        strategy: 'Original (Fallback)',
        processingTime: DateTime.now().difference(startTime),
        attemptsCount: 1,
      );
    }
  }

  /// Attempt OCR on an image
  Future<OCRAttempt> _attemptOCR(
    String imagePath,
    String strategy,
    PreprocessedResult? preprocessedResult,
  ) async {
    final startTime = DateTime.now();

    final receipt = await _baseOCRService.scanReceipt(imagePath);
    final duration = DateTime.now().difference(startTime);

    // Calculate quality score
    final quality = _calculateQualityScore(receipt);

    return OCRAttempt(
      receipt: receipt,
      strategy: strategy,
      duration: duration,
      qualityScore: quality,
      preprocessedResult: preprocessedResult,
    );
  }

  /// Calculate quality score for OCR result
  double _calculateQualityScore(ExtractedReceipt receipt) {
    double score = 0.0;
    int maxScore = 0;

    // Merchant name (25 points)
    maxScore += 25;
    if (receipt.merchantName != null && receipt.merchantName!.isNotEmpty) {
      score += 25 * (receipt.fieldConfidences['merchant'] ?? 0.5);
    }

    // Date (20 points)
    maxScore += 20;
    if (receipt.date != null) {
      score += 20 * (receipt.fieldConfidences['date'] ?? 0.5);
    }

    // Total amount (30 points)
    maxScore += 30;
    if (receipt.totalAmount != null && receipt.totalAmount! > 0) {
      score += 30 * (receipt.fieldConfidences['total'] ?? 0.5);
    }

    // Items extracted (25 points)
    maxScore += 25;
    if (receipt.items.isNotEmpty) {
      final itemsScore = (receipt.items.length / 10).clamp(0.0, 1.0);
      score += 25 * itemsScore * (receipt.fieldConfidences['items'] ?? 0.5);
    }

    // Text clarity bonus (based on text length)
    if (receipt.rawText.length > 100) {
      score += 5;
      maxScore += 5;
    }

    return maxScore > 0 ? (score / maxScore) : 0.0;
  }

  /// Select best OCR result from all attempts
  OCRAttempt _selectBestResult(List<OCRAttempt> attempts) {
    if (attempts.isEmpty) {
      throw Exception('No OCR attempts available');
    }

    // Sort by quality score (descending)
    attempts.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

    // Return best result
    return attempts.first;
  }

  /// Get detailed comparison of all OCR attempts
  String getAttemptsComparison(List<OCRAttempt> attempts) {
    final buffer = StringBuffer();
    buffer.writeln('OCR Attempts Comparison:');
    buffer.writeln('=' * 50);

    attempts.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      buffer.writeln();
      buffer.writeln('${i + 1}. ${attempt.strategy}');
      buffer.writeln('   Quality Score: ${(attempt.qualityScore * 100).toStringAsFixed(1)}%');
      buffer.writeln('   Processing Time: ${attempt.duration.inMilliseconds}ms');
      buffer.writeln('   Merchant: ${attempt.receipt.merchantName ?? "Not found"}');
      buffer.writeln('   Date: ${attempt.receipt.date?.toString() ?? "Not found"}');
      buffer.writeln('   Total: ₹${attempt.receipt.totalAmount?.toStringAsFixed(2) ?? "Not found"}');
      buffer.writeln('   Items Found: ${attempt.receipt.items.length}');
      buffer.writeln('   Text Length: ${attempt.receipt.rawText.length} chars');
    }

    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    _baseOCRService.dispose();
  }
}

/// Result of an OCR attempt
class OCRAttempt {
  final ExtractedReceipt receipt;
  final String strategy;
  final Duration duration;
  final double qualityScore; // 0.0 to 1.0
  final PreprocessedResult? preprocessedResult;

  OCRAttempt({
    required this.receipt,
    required this.strategy,
    required this.duration,
    required this.qualityScore,
    this.preprocessedResult,
  });

  Map<String, dynamic> toJson() => {
        'strategy': strategy,
        'duration_ms': duration.inMilliseconds,
        'quality_score': qualityScore,
        'merchant_found': receipt.merchantName != null,
        'date_found': receipt.date != null,
        'total_found': receipt.totalAmount != null,
        'items_count': receipt.items.length,
        'text_length': receipt.rawText.length,
      };
}

/// Enhanced OCR result with metadata
class EnhancedOCRResult {
  final ExtractedReceipt receipt;
  final String strategy; // Which strategy produced this result
  final Duration processingTime;
  final int attemptsCount;
  final List<OCRAttempt>? allAttempts; // Optional: all attempts for comparison

  EnhancedOCRResult({
    required this.receipt,
    required this.strategy,
    required this.processingTime,
    required this.attemptsCount,
    this.allAttempts,
  });

  /// Get quality score of best result
  double get qualityScore {
    if (allAttempts != null && allAttempts!.isNotEmpty) {
      return allAttempts!
          .map((a) => a.qualityScore)
          .reduce((a, b) => a > b ? a : b);
    }
    return receipt.confidence;
  }

  /// Get detailed metrics
  Map<String, dynamic> getMetrics() => {
        'strategy_used': strategy,
        'processing_time_ms': processingTime.inMilliseconds,
        'attempts_count': attemptsCount,
        'quality_score': qualityScore,
        'merchant_extracted': receipt.merchantName != null,
        'date_extracted': receipt.date != null,
        'total_extracted': receipt.totalAmount != null,
        'items_extracted': receipt.items.length,
        'confidence': receipt.confidence,
        'text_length': receipt.rawText.length,
      };

  Map<String, dynamic> toJson() => {
        'receipt': receipt.toJson(),
        'strategy': strategy,
        'processing_time_ms': processingTime.inMilliseconds,
        'attempts_count': attemptsCount,
        'quality_score': qualityScore,
        'metrics': getMetrics(),
      };
}

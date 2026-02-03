import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'enhanced_receipt_ocr_service.dart';
import 'receipt_ocr_service.dart';
import '../models/transaction.dart';

/// Service for batch operations on receipts
class ReceiptBatchService {
  final EnhancedReceiptOCRService _ocrService = EnhancedReceiptOCRService();

  /// Batch scan multiple receipts
  /// Returns stream of progress updates
  Stream<BatchScanProgress> batchScanReceipts(
    List<String> imagePaths, {
    bool useMultiPass = true,
    bool detectDuplicates = true,
  }) async* {
    final results = <BatchScanResult>[];
    final duplicates = <int>[];

    for (var i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];

      yield BatchScanProgress(
        current: i + 1,
        total: imagePaths.length,
        currentFile: path.basename(imagePath),
        status: 'Scanning...',
        results: List.from(results),
      );

      try {
        // Scan receipt
        final ocrResult = await _ocrService.scanReceiptEnhanced(
          imagePath,
          useMultiPass: useMultiPass,
        );

        // Check for duplicates
        bool isDuplicate = false;
        if (detectDuplicates && results.isNotEmpty) {
          isDuplicate = _checkDuplicate(ocrResult.receipt, results);
          if (isDuplicate) {
            duplicates.add(i);
          }
        }

        final result = BatchScanResult(
          imagePath: imagePath,
          receipt: ocrResult.receipt,
          strategy: ocrResult.strategy,
          processingTime: ocrResult.processingTime,
          isDuplicate: isDuplicate,
          error: null,
        );

        results.add(result);
      } catch (e) {
        final result = BatchScanResult(
          imagePath: imagePath,
          receipt: null,
          strategy: 'Failed',
          processingTime: Duration.zero,
          isDuplicate: false,
          error: e.toString(),
        );
        results.add(result);
      }
    }

    // Final progress update
    yield BatchScanProgress(
      current: imagePaths.length,
      total: imagePaths.length,
      currentFile: 'Complete',
      status: 'Finished',
      results: results,
      duplicatesFound: duplicates.length,
    );
  }

  /// Check if receipt is duplicate
  bool _checkDuplicate(
    ExtractedReceipt newReceipt,
    List<BatchScanResult> existingResults,
  ) {
    for (final existing in existingResults) {
      if (existing.receipt == null) continue;

      final similarity = _calculateSimilarity(newReceipt, existing.receipt!);
      if (similarity > 0.85) {
        // 85% similarity threshold
        return true;
      }
    }
    return false;
  }

  /// Calculate similarity between two receipts (0.0 to 1.0)
  double _calculateSimilarity(
    ExtractedReceipt receipt1,
    ExtractedReceipt receipt2,
  ) {
    double score = 0.0;
    int checks = 0;

    // Check merchant name
    checks++;
    if (receipt1.merchantName != null && receipt2.merchantName != null) {
      if (receipt1.merchantName!.toLowerCase() ==
          receipt2.merchantName!.toLowerCase()) {
        score += 1.0;
      } else if (_stringSimilarity(
              receipt1.merchantName!, receipt2.merchantName!) >
          0.8) {
        score += 0.7;
      }
    }

    // Check date
    checks++;
    if (receipt1.date != null && receipt2.date != null) {
      if (receipt1.date == receipt2.date) {
        score += 1.0;
      } else {
        final diff = receipt1.date!.difference(receipt2.date!).abs();
        if (diff.inDays == 0) {
          score += 0.5; // Same day but different time
        }
      }
    }

    // Check total amount
    checks++;
    if (receipt1.totalAmount != null && receipt2.totalAmount != null) {
      final diff = (receipt1.totalAmount! - receipt2.totalAmount!).abs();
      if (diff < 0.01) {
        // Exact match
        score += 1.0;
      } else if (diff < 1.0) {
        // Very close
        score += 0.8;
      } else if (diff < receipt1.totalAmount! * 0.05) {
        // Within 5%
        score += 0.5;
      }
    }

    // Check items count
    checks++;
    if (receipt1.items.isNotEmpty && receipt2.items.isNotEmpty) {
      final itemsMatch = receipt1.items.length == receipt2.items.length;
      score += itemsMatch ? 1.0 : 0.5;
    }

    // Check raw text similarity (Levenshtein distance)
    checks++;
    final textSimilarity = _stringSimilarity(
      receipt1.rawText,
      receipt2.rawText,
    );
    score += textSimilarity;

    return checks > 0 ? score / checks : 0.0;
  }

  /// Calculate string similarity using Levenshtein distance
  double _stringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    final distance = _levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());

    return 1.0 - (distance / maxLen);
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(len1 + 1, (_) => List.filled(len2 + 1, 0));

    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Export receipts to ZIP file
  Future<String> exportReceiptsToZip(
    List<Transaction> transactions,
    String userId, {
    String? outputPath,
  }) async {
    final archive = Archive();

    // Create receipts metadata JSON
    final metadata = {
      'export_date': DateTime.now().toIso8601String(),
      'user_id': userId,
      'receipts_count': transactions.length,
      'receipts': [],
    };

    // Add receipt images and data
    for (var i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];

      // Skip if no receipt
      if (transaction.receiptImagePath == null ||
          transaction.receiptImagePath!.isEmpty) {
        continue;
      }

      try {
        // Get receipt image
        final appDir = await getApplicationDocumentsDirectory();
        final imagePath = path.join(
          appDir.path,
          'receipts',
          userId,
          transaction.receiptImagePath!,
        );

        final imageFile = File(imagePath);
        if (!await imageFile.exists()) continue;

        // Read image bytes
        final imageBytes = await imageFile.readAsBytes();

        // Add to archive
        final fileName = 'receipt_${i + 1}_${path.basename(imagePath)}';
        archive.addFile(ArchiveFile(
          fileName,
          imageBytes.length,
          imageBytes,
        ));

        // Add receipt metadata
        metadata['receipts'].add({
          'file_name': fileName,
          'transaction_id': transaction.id,
          'merchant': transaction.merchant,
          'amount': transaction.amount,
          'date': transaction.date.toIso8601String(),
          'receipt_data': transaction.receiptData,
        });
      } catch (e) {
        print('Error adding receipt $i to ZIP: $e');
      }
    }

    // Add metadata JSON
    final metadataJson = metadata.toString();
    archive.addFile(ArchiveFile(
      'metadata.json',
      metadataJson.length,
      metadataJson.codeUnits,
    ));

    // Encode ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    // Save to file
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = outputPath ??
        path.join(
          tempDir.path,
          'expenwall_receipts_$timestamp.zip',
        );

    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes!);

    return zipPath;
  }

  /// Import receipts from ZIP file
  Future<ImportResult> importReceiptsFromZip(
    String zipPath,
    String userId,
  ) async {
    try {
      // Read ZIP file
      final zipFile = File(zipPath);
      final zipBytes = await zipFile.readAsBytes();

      // Decode ZIP
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Extract to temporary directory
      final tempDir = await getTemporaryDirectory();
      final extractPath = path.join(
        tempDir.path,
        'import_${DateTime.now().millisecondsSinceEpoch}',
      );
      await Directory(extractPath).create(recursive: true);

      final extractedPaths = <String>[];

      for (final file in archive) {
        if (file.isFile) {
          final filePath = path.join(extractPath, file.name);
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);

          // Track image files
          if (file.name.endsWith('.jpg') ||
              file.name.endsWith('.jpeg') ||
              file.name.endsWith('.png')) {
            extractedPaths.add(filePath);
          }
        }
      }

      return ImportResult(
        success: true,
        extractedFiles: extractedPaths,
        message: 'Successfully imported ${extractedPaths.length} receipts',
      );
    } catch (e) {
      return ImportResult(
        success: false,
        extractedFiles: [],
        message: 'Import failed: $e',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _ocrService.dispose();
  }
}

/// Progress update for batch scanning
class BatchScanProgress {
  final int current;
  final int total;
  final String currentFile;
  final String status;
  final List<BatchScanResult> results;
  final int? duplicatesFound;

  BatchScanProgress({
    required this.current,
    required this.total,
    required this.currentFile,
    required this.status,
    required this.results,
    this.duplicatesFound,
  });

  double get progress => total > 0 ? current / total : 0.0;
  int get successCount => results.where((r) => r.receipt != null).length;
  int get errorCount => results.where((r) => r.error != null).length;
}

/// Result of scanning a single receipt in batch
class BatchScanResult {
  final String imagePath;
  final ExtractedReceipt? receipt;
  final String strategy;
  final Duration processingTime;
  final bool isDuplicate;
  final String? error;

  BatchScanResult({
    required this.imagePath,
    required this.receipt,
    required this.strategy,
    required this.processingTime,
    required this.isDuplicate,
    this.error,
  });

  bool get isSuccess => receipt != null && error == null;
}

/// Result of importing receipts from ZIP
class ImportResult {
  final bool success;
  final List<String> extractedFiles;
  final String message;

  ImportResult({
    required this.success,
    required this.extractedFiles,
    required this.message,
  });
}

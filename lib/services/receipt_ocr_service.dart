import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'item_recognition_service.dart';

/// Represents an extracted receipt with all parsed information
class ExtractedReceipt {
  final String? merchantName;
  final DateTime? date;
  final double? totalAmount;
  final List<ReceiptItem> items;
  final String rawText;
  final double confidence; // Overall extraction confidence (0.0 to 1.0)
  final Map<String, double> fieldConfidences; // Per-field confidence scores

  ExtractedReceipt({
    this.merchantName,
    this.date,
    this.totalAmount,
    this.items = const [],
    required this.rawText,
    this.confidence = 0.0,
    this.fieldConfidences = const {},
  });

  Map<String, dynamic> toJson() => {
        'merchantName': merchantName,
        'date': date?.toIso8601String(),
        'totalAmount': totalAmount,
        'items': items.map((item) => item.toJson()).toList(),
        'rawText': rawText,
        'confidence': confidence,
        'fieldConfidences': fieldConfidences,
      };

  factory ExtractedReceipt.fromJson(Map<String, dynamic> json) =>
      ExtractedReceipt(
        merchantName: json['merchantName'],
        date: json['date'] != null ? DateTime.parse(json['date']) : null,
        totalAmount: json['totalAmount']?.toDouble(),
        items: (json['items'] as List?)
                ?.map((item) => ReceiptItem.fromJson(item))
                .toList() ??
            [],
        rawText: json['rawText'] ?? '',
        confidence: json['confidence']?.toDouble() ?? 0.0,
        fieldConfidences: Map<String, double>.from(json['fieldConfidences'] ?? {}),
      );
}

/// Represents a single item on a receipt
class ReceiptItem {
  final String name;
  final double price;
  final int quantity;
  final String? category;
  final String? subcategory;
  final double confidence;

  ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category,
    this.subcategory,
    this.confidence = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'category': category,
        'subcategory': subcategory,
        'confidence': confidence,
      };

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        name: json['name'] ?? '',
        price: json['price']?.toDouble() ?? 0.0,
        quantity: json['quantity'] ?? 1,
        category: json['category'],
        subcategory: json['subcategory'],
        confidence: json['confidence']?.toDouble() ?? 0.0,
      );
}

/// Service for extracting information from receipt images using Google ML Kit
class ReceiptOCRService {
  final TextRecognizer _textRecognizer;
  final ItemRecognitionService _itemRecognitionService;

  // Common Indian merchant patterns
  static final _merchantPatterns = [
    // Retail chains
    RegExp(r'\b(D[- ]?MART|DMART)\b', caseSensitive: false),
    RegExp(r'\b(BIG\s*BAZAAR|BIGBAZAAR)\b', caseSensitive: false),
    RegExp(r'\b(MORE\s*MEGA\s*STORE|MORE)\b', caseSensitive: false),
    RegExp(r'\b(RELIANCE\s*FRESH|RELIANCE\s*SMART)\b', caseSensitive: false),
    RegExp(r'\b(SPENCER\'?S|SPENCERS)\b', caseSensitive: false),
    RegExp(r'\b(VISHAL\s*MEGA\s*MART)\b', caseSensitive: false),
    RegExp(r'\b(STAR\s*BAZAAR)\b', caseSensitive: false),
    
    // Food delivery
    RegExp(r'\b(SWIGGY)\b', caseSensitive: false),
    RegExp(r'\b(ZOMATO)\b', caseSensitive: false),
    RegExp(r'\b(UBER\s*EATS)\b', caseSensitive: false),
    
    // Restaurants
    RegExp(r'\b(MCDONALD\'?S|MC\s*DONALD\'?S)\b', caseSensitive: false),
    RegExp(r'\b(KFC|KENTUCKY\s*FRIED\s*CHICKEN)\b', caseSensitive: false),
    RegExp(r'\b(DOMINO\'?S|DOMINOS)\b', caseSensitive: false),
    RegExp(r'\b(PIZZA\s*HUT)\b', caseSensitive: false),
    RegExp(r'\b(SUBWAY)\b', caseSensitive: false),
    RegExp(r'\b(BURGER\s*KING)\b', caseSensitive: false),
    
    // Pharmacies
    RegExp(r'\b(APOLLO\s*PHARMACY)\b', caseSensitive: false),
    RegExp(r'\b(MEDPLUS)\b', caseSensitive: false),
    RegExp(r'\b(WELLNESS\s*FOREVER)\b', caseSensitive: false),
    
    // Electronics
    RegExp(r'\b(CROMA)\b', caseSensitive: false),
    RegExp(r'\b(VIJAY\s*SALES)\b', caseSensitive: false),
    RegExp(r'\b(RELIANCE\s*DIGITAL)\b', caseSensitive: false),
  ];

  // Date patterns (DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, etc.)
  static final _datePatterns = [
    RegExp(r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})\b'), // DD/MM/YYYY
    RegExp(r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2})\b'), // DD/MM/YY
    RegExp(r'\b(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})\b'), // YYYY/MM/DD
  ];

  // Amount patterns (₹, Rs., INR)
  static final _amountPatterns = [
    RegExp(r'₹\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
    RegExp(r'Rs\.?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
    RegExp(r'INR\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
    RegExp(r'\b(\d+(?:,\d{3})*\.\d{2})\s*(?=total|grand|payable|amount)', caseSensitive: false),
  ];

  // Total amount keywords
  static final _totalKeywords = [
    'total',
    'grand total',
    'net total',
    'amount payable',
    'payable amount',
    'bill amount',
    'total amount',
    'net amount',
    'final amount',
    'total Rs',
    'total INR',
  ];

  // Item line patterns (typical receipt format)
  static final _itemLinePattern = RegExp(
    r'^(.+?)\s+(\d+(?:\.\d{2})?|\d+,\d{3}(?:\.\d{2})?)\s*$',
    multiLine: true,
  );

  ReceiptOCRService()
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin),
        _itemRecognitionService = ItemRecognitionService();

  /// Extract text and information from a receipt image
  Future<ExtractedReceipt> scanReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      final lines = _extractLines(recognizedText);

      // Extract various fields
      final merchant = _extractMerchant(lines, rawText);
      final date = _extractDate(lines, rawText);
      final total = _extractTotalAmount(lines, rawText);
      final items = _extractItems(lines);

      // Calculate confidence scores
      final fieldConfidences = {
        'merchant': merchant != null ? 0.8 : 0.0,
        'date': date != null ? 0.7 : 0.0,
        'total': total != null ? 0.9 : 0.0,
        'items': items.isNotEmpty ? 0.6 : 0.0,
      };

      final overallConfidence = fieldConfidences.values.reduce((a, b) => a + b) /
          fieldConfidences.length;

      return ExtractedReceipt(
        merchantName: merchant,
        date: date,
        totalAmount: total,
        items: items,
        rawText: rawText,
        confidence: overallConfidence,
        fieldConfidences: fieldConfidences,
      );
    } catch (e) {
      print('Error scanning receipt: $e');
      return ExtractedReceipt(
        rawText: '',
        confidence: 0.0,
      );
    }
  }

  /// Extract text lines from recognized text
  List<String> _extractLines(RecognizedText recognizedText) {
    final lines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        lines.add(line.text.trim());
      }
    }
    return lines;
  }

  /// Extract merchant name from receipt
  String? _extractMerchant(List<String> lines, String rawText) {
    // Try pattern matching first
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        return _cleanMerchantName(match.group(0)!);
      }
    }

    // Fallback: Use ItemRecognitionService for merchant recognition
    for (final line in lines.take(5)) {
      // Check first 5 lines
      final match = _itemRecognitionService.recognizeMerchant(line);
      if (match != null && match.confidence > 0.6) {
        return line;
      }
    }

    // Last resort: Return first line if it looks like a business name
    if (lines.isNotEmpty && _looksLikeMerchantName(lines.first)) {
      return lines.first;
    }

    return null;
  }

  /// Check if a line looks like a merchant name
  bool _looksLikeMerchantName(String line) {
    // Merchant names are usually:
    // - All caps or title case
    // - Short (less than 50 chars)
    // - Don't start with numbers
    // - Don't contain too many special characters
    if (line.length > 50) return false;
    if (RegExp(r'^\d').hasMatch(line)) return false;
    if (RegExp(r'[₹Rs\.]').hasMatch(line)) return false;

    final uppercaseRatio =
        line.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length /
            line.length;

    return uppercaseRatio > 0.5 || _isInTitleCase(line);
  }

  /// Check if string is in title case
  bool _isInTitleCase(String text) {
    final words = text.split(' ');
    return words.every((word) =>
        word.isNotEmpty && word[0] == word[0].toUpperCase());
  }

  /// Clean up merchant name
  String _cleanMerchantName(String name) {
    return name
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  /// Extract date from receipt
  DateTime? _extractDate(List<String> lines, String rawText) {
    for (final pattern in _datePatterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        try {
          // Try different date formats
          if (match.groupCount >= 3) {
            int day, month, year;

            // Detect format based on values
            final part1 = int.parse(match.group(1)!);
            final part2 = int.parse(match.group(2)!);
            final part3 = int.parse(match.group(3)!);

            if (part3 > 31) {
              // YYYY/MM/DD format
              year = part3;
              month = part2;
              day = part1;
            } else {
              // DD/MM/YYYY format
              day = part1;
              month = part2;
              year = part3;
            }

            // Handle 2-digit years
            if (year < 100) {
              year += 2000;
            }

            // Validate date
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
              return DateTime(year, month, day);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  /// Extract total amount from receipt
  double? _extractTotalAmount(List<String> lines, String rawText) {
    // Look for total keywords and nearby amounts
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Check if line contains total keyword
      if (_totalKeywords.any((keyword) => line.contains(keyword.toLowerCase()))) {
        // Search this line and next few lines for amount
        for (var j = i; j < i + 3 && j < lines.length; j++) {
          final amount = _extractAmountFromLine(lines[j]);
          if (amount != null) {
            return amount;
          }
        }
      }
    }

    // Fallback: Find largest amount in receipt
    double? maxAmount;
    for (final line in lines) {
      final amount = _extractAmountFromLine(line);
      if (amount != null && (maxAmount == null || amount > maxAmount)) {
        maxAmount = amount;
      }
    }

    return maxAmount;
  }

  /// Extract amount value from a line
  double? _extractAmountFromLine(String line) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        try {
          final amountStr = match.group(1)!.replaceAll(',', '');
          return double.parse(amountStr);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  /// Extract items from receipt
  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];

    for (final line in lines) {
      // Skip lines that look like headers, totals, or merchant info
      if (_isHeaderOrTotal(line)) continue;

      // Try to parse as item line
      final item = _parseItemLine(line);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  /// Check if line is a header or total line
  bool _isHeaderOrTotal(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('total') ||
        lowerLine.contains('subtotal') ||
        lowerLine.contains('tax') ||
        lowerLine.contains('discount') ||
        lowerLine.contains('item') ||
        lowerLine.contains('qty') ||
        lowerLine.contains('price') ||
        lowerLine.contains('amount') ||
        line.length < 3;
  }

  /// Parse a line as an item
  ReceiptItem? _parseItemLine(String line) {
    // Try standard item format: "Item Name  Price"
    final match = _itemLinePattern.firstMatch(line);
    if (match != null) {
      try {
        final name = match.group(1)!.trim();
        final priceStr = match.group(2)!.replaceAll(',', '');
        final price = double.parse(priceStr);

        // Skip if price is too high (likely a total)
        if (price > 10000) return null;

        // Try to recognize item and get category
        final recognition = _itemRecognitionService.recognizeItem(name);

        return ReceiptItem(
          name: name,
          price: price,
          quantity: 1,
          category: recognition?.category,
          subcategory: recognition?.subcategory,
          confidence: recognition?.confidence ?? 0.5,
        );
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Dispose the text recognizer
  void dispose() {
    _textRecognizer.close();
  }
}

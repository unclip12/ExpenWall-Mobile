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
    RegExp(r"\b(SPENCER'?S|SPENCERS)\b", caseSensitive: false),
    RegExp(r'\b(VISHAL\s*MEGA\s*MART)\b', caseSensitive: false),
    RegExp(r'\b(STAR\s*BAZAAR)\b', caseSensitive: false),
    
    // Food delivery
    RegExp(r'\b(SWIGGY)\b', caseSensitive: false),
    RegExp(r'\b(ZOMATO)\b', caseSensitive: false),
    RegExp(r'\b(UBER\s*EATS)\b', caseSensitive: false),
    
    // Restaurants
    RegExp(r"\b(MCDONALD'?S|MC\s*DONALD'?S)\b", caseSensitive: false),
    RegExp(r'\b(KFC|KENTUCKY\s*FRIED\s*CHICKEN)\b', caseSensitive: false),
    RegExp(r"\b(DOMINO'?S|DOMINOS)\b", caseSensitive: false),
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
    'net payable',
    'amount to be paid',
  ];

  // IMPROVED: Multiple item line patterns for Indian receipts
  static final _itemLinePatterns = [
    // Format 1: "Item Name  Price" (standard)
    RegExp(r'^(.+?)\s{2,}(\d+(?:\.\d{2})?|\d+,\d{3}(?:\.\d{2})?)\s*$'),
    
    // Format 2: "Item Name Price" (single space)
    RegExp(r'^(.{3,}?)\s+(\d+\.\d{2})\s*$'),
    
    // Format 3: "Qty x Price = Total" (e.g., "2 x 50.00 = 100.00")
    RegExp(r'^(.+?)\s+(\d+)\s*[xX*]\s*(\d+\.?\d{0,2})(?:\s*=?\s*(\d+\.?\d{0,2}))?'),
    
    // Format 4: "Item  Qty  Price" (DMart style)
    RegExp(r'^(.+?)\s+(\d+)\s+(\d+\.\d{2})\s*$'),
    
    // Format 5: "Item Name\nPrice" (multi-line)
    RegExp(r'^(.+)$'),
  ];

  // Skip patterns (lines to ignore)
  static final _skipPatterns = [
    RegExp(r'^\s*[-=*]+\s*$'), // Separator lines
    RegExp(r'^\s*$'), // Empty lines
    RegExp(r'\b(subtotal|sub total|sub-total)\b', caseSensitive: false),
    RegExp(r'\b(tax|vat|gst|cgst|sgst)\b', caseSensitive: false),
    RegExp(r'\b(discount|savings|offer)\b', caseSensitive: false),
    RegExp(r'\b(barcode|code|sku)\b', caseSensitive: false),
    RegExp(r'^\d{12,}$'), // Barcode numbers
  ];

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
      final items = _extractItems(lines, rawText);

      // IMPROVED: Smart confidence calculation
      final fieldConfidences = _calculateFieldConfidences(
        merchant: merchant,
        date: date,
        total: total,
        items: items,
        rawText: rawText,
      );

      final overallConfidence = _calculateOverallConfidence(fieldConfidences, items, total);

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

  /// IMPROVED: Smart confidence calculation
  Map<String, double> _calculateFieldConfidences({
    required String? merchant,
    required DateTime? date,
    required double? total,
    required List<ReceiptItem> items,
    required String rawText,
  }) {
    final confidences = <String, double>{};

    // Merchant confidence (0.0 to 1.0)
    if (merchant != null) {
      if (_merchantPatterns.any((p) => p.hasMatch(merchant))) {
        confidences['merchant'] = 0.95; // Known merchant
      } else if (merchant.length > 3) {
        confidences['merchant'] = 0.75; // Probable merchant
      } else {
        confidences['merchant'] = 0.5; // Weak match
      }
    } else {
      confidences['merchant'] = 0.0;
    }

    // Date confidence
    if (date != null) {
      final now = DateTime.now();
      final diffDays = now.difference(date).inDays.abs();
      if (diffDays <= 30) {
        confidences['date'] = 0.9; // Recent date
      } else if (diffDays <= 365) {
        confidences['date'] = 0.7; // Within year
      } else {
        confidences['date'] = 0.4; // Old date
      }
    } else {
      confidences['date'] = 0.0;
    }

    // Total amount confidence
    if (total != null) {
      if (total > 0 && total < 1000000) {
        confidences['total'] = 0.95; // Reasonable amount
      } else {
        confidences['total'] = 0.6; // Suspicious amount
      }
    } else {
      confidences['total'] = 0.0;
    }

    // Items confidence (based on quantity and quality)
    if (items.isNotEmpty) {
      final itemsWithCategory = items.where((i) => i.category != null).length;
      final avgItemConfidence = items.fold(0.0, (sum, i) => sum + i.confidence) / items.length;
      
      // More items = higher confidence (up to 10 items)
      final quantityScore = (items.length / 10.0).clamp(0.0, 1.0);
      
      // Items with categories = higher confidence
      final categoryScore = items.length > 0 ? (itemsWithCategory / items.length) : 0.0;
      
      confidences['items'] = (quantityScore * 0.4 + categoryScore * 0.3 + avgItemConfidence * 0.3);
    } else {
      confidences['items'] = 0.0;
    }

    // Text quality (readability)
    final textLength = rawText.replaceAll(RegExp(r'\s+'), '').length;
    if (textLength > 100) {
      confidences['text_quality'] = 0.8;
    } else if (textLength > 50) {
      confidences['text_quality'] = 0.6;
    } else {
      confidences['text_quality'] = 0.3;
    }

    return confidences;
  }

  /// IMPROVED: Weighted overall confidence calculation
  double _calculateOverallConfidence(
    Map<String, double> fieldConfidences,
    List<ReceiptItem> items,
    double? total,
  ) {
    // Weighted scores (critical fields matter more)
    final weights = {
      'total': 0.30,      // Most critical
      'merchant': 0.25,   // Very important
      'items': 0.25,      // Very important
      'date': 0.15,       // Important
      'text_quality': 0.05, // Nice to have
    };

    double score = 0.0;
    double totalWeight = 0.0;

    fieldConfidences.forEach((field, confidence) {
      final weight = weights[field] ?? 0.0;
      score += confidence * weight;
      totalWeight += weight;
    });

    double baseConfidence = totalWeight > 0 ? score / totalWeight : 0.0;

    // Bonus points for validation
    if (items.isNotEmpty && total != null) {
      final itemsTotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
      final diff = (itemsTotal - total).abs();
      final diffPercent = total > 0 ? diff / total : 1.0;
      
      // If items total matches receipt total (within 5%), big bonus
      if (diffPercent < 0.05) {
        baseConfidence = (baseConfidence + 0.15).clamp(0.0, 1.0);
      } else if (diffPercent < 0.15) {
        baseConfidence = (baseConfidence + 0.05).clamp(0.0, 1.0);
      }
    }

    // Penalty for critical missing fields
    if (total == null) baseConfidence *= 0.6;
    if (items.isEmpty) baseConfidence *= 0.7;

    return baseConfidence;
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
          if (match.groupCount >= 3) {
            int day, month, year;

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

    // Fallback: Find largest amount in receipt (likely the total)
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

  /// IMPROVED: Extract items from receipt (handles multiple formats)
  List<ReceiptItem> _extractItems(List<String> lines, String rawText) {
    final items = <ReceiptItem>[];
    String? pendingItemName;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Skip empty or skip-pattern lines
      if (line.isEmpty || _skipPatterns.any((p) => p.hasMatch(line))) {
        continue;
      }

      // Skip header/total lines
      if (_isHeaderOrTotal(line)) {
        continue;
      }

      // Try all item patterns
      ReceiptItem? item;
      
      // Try pattern 3: Qty x Price format
      final qtyPriceMatch = _itemLinePatterns[2].firstMatch(line);
      if (qtyPriceMatch != null && qtyPriceMatch.groupCount >= 3) {
        try {
          final name = qtyPriceMatch.group(1)!.trim();
          final qty = int.parse(qtyPriceMatch.group(2)!);
          final price = double.parse(qtyPriceMatch.group(3)!);
          
          item = _createReceiptItem(name, price, qty);
        } catch (e) {
          // Continue to next pattern
        }
      }

      // Try pattern 4: Item Qty Price (DMart style)
      if (item == null) {
        final dmartMatch = _itemLinePatterns[3].firstMatch(line);
        if (dmartMatch != null && dmartMatch.groupCount >= 3) {
          try {
            final name = dmartMatch.group(1)!.trim();
            final qty = int.parse(dmartMatch.group(2)!);
            final price = double.parse(dmartMatch.group(3)!);
            
            item = _createReceiptItem(name, price, qty);
          } catch (e) {
            // Continue
          }
        }
      }

      // Try pattern 1: Standard "Item  Price"
      if (item == null) {
        final standardMatch = _itemLinePatterns[0].firstMatch(line);
        if (standardMatch != null) {
          try {
            final name = standardMatch.group(1)!.trim();
            final priceStr = standardMatch.group(2)!.replaceAll(',', '');
            final price = double.parse(priceStr);
            
            if (price > 0 && price < 100000) {
              item = _createReceiptItem(name, price, 1);
            }
          } catch (e) {
            // Continue
          }
        }
      }

      // Try pattern 2: Simple "Item Price"
      if (item == null) {
        final simpleMatch = _itemLinePatterns[1].firstMatch(line);
        if (simpleMatch != null) {
          try {
            final name = simpleMatch.group(1)!.trim();
            final price = double.parse(simpleMatch.group(2)!);
            
            if (price > 0 && price < 100000) {
              item = _createReceiptItem(name, price, 1);
            }
          } catch (e) {
            // Continue
          }
        }
      }

      // Handle multi-line items (item name on one line, price on next)
      if (item == null && pendingItemName != null) {
        final amount = _extractAmountFromLine(line);
        if (amount != null && amount < 10000) {
          item = _createReceiptItem(pendingItemName, amount, 1);
          pendingItemName = null;
        }
      }

      // If we found an item, add it
      if (item != null) {
        items.add(item);
        pendingItemName = null;
      } else if (_looksLikeItemName(line)) {
        // Store as pending item name
        pendingItemName = line;
      }
    }

    return items;
  }

  /// Create a receipt item with category recognition
  ReceiptItem _createReceiptItem(String name, double price, int quantity) {
    final recognition = _itemRecognitionService.recognizeItem(name);

    return ReceiptItem(
      name: name,
      price: price,
      quantity: quantity,
      category: recognition?.category,
      subcategory: recognition?.subcategory,
      confidence: recognition?.confidence ?? 0.6,
    );
  }

  /// Check if line looks like an item name
  bool _looksLikeItemName(String line) {
    if (line.length < 3 || line.length > 80) return false;
    if (RegExp(r'^\d+$').hasMatch(line)) return false; // Just numbers
    if (RegExp(r'^[^a-zA-Z]+$').hasMatch(line)) return false; // No letters
    if (_extractAmountFromLine(line) != null) return false; // Contains amount
    
    return true;
  }

  /// Check if line is a header or total line
  bool _isHeaderOrTotal(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('total') ||
        lowerLine.contains('subtotal') ||
        lowerLine.contains('sub total') ||
        lowerLine.contains('tax') ||
        lowerLine.contains('discount') ||
        lowerLine.contains('savings') ||
        lowerLine.contains('item') && lowerLine.contains('qty') ||
        lowerLine.contains('price') && lowerLine.length < 10 ||
        lowerLine.contains('amount') && lowerLine.length < 15 ||
        line.length < 2;
  }

  /// Dispose the text recognizer
  void dispose() {
    _textRecognizer.close();
  }
}

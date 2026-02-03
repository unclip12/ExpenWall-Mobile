import 'receipt_ocr_service.dart';

/// Service for recognizing receipt templates and applying specialized parsing
class ReceiptTemplateService {
  /// Detect which template a receipt matches
  static ReceiptTemplate? detectTemplate(ExtractedReceipt receipt) {
    final text = receipt.rawText.toLowerCase();
    final merchant = receipt.merchantName?.toLowerCase() ?? '';

    // Check each template
    for (final template in ReceiptTemplate.values) {
      if (_matchesTemplate(text, merchant, template)) {
        return template;
      }
    }

    return null;
  }

  /// Check if receipt matches a specific template
  static bool _matchesTemplate(
    String text,
    String merchant,
    ReceiptTemplate template,
  ) {
    switch (template) {
      case ReceiptTemplate.dmart:
        return merchant.contains('dmart') ||
            merchant.contains('d-mart') ||
            text.contains('avenue supermarts');

      case ReceiptTemplate.bigBazaar:
        return merchant.contains('big bazaar') ||
            merchant.contains('bigbazaar') ||
            text.contains('future retail');

      case ReceiptTemplate.reliance:
        return merchant.contains('reliance') &&
            (merchant.contains('fresh') ||
                merchant.contains('smart') ||
                merchant.contains('digital'));

      case ReceiptTemplate.more:
        return merchant.contains('more') &&
            (merchant.contains('mega') || merchant.contains('store'));

      case ReceiptTemplate.swiggy:
        return merchant.contains('swiggy') || text.contains('bundl technologies');

      case ReceiptTemplate.zomato:
        return merchant.contains('zomato') || text.contains('zomato ltd');

      case ReceiptTemplate.mcdonalds:
        return merchant.contains('mcdonald') ||
            merchant.contains('mc donald') ||
            text.contains('golden arches');

      case ReceiptTemplate.kfc:
        return merchant.contains('kfc') ||
            merchant.contains('kentucky fried chicken') ||
            text.contains('yum! restaurants');

      case ReceiptTemplate.dominos:
        return merchant.contains('domino') ||
            text.contains('jubilant foodworks');

      case ReceiptTemplate.pizzaHut:
        return merchant.contains('pizza hut') || text.contains('pizza hut');

      case ReceiptTemplate.apollo:
        return merchant.contains('apollo') &&
            (merchant.contains('pharmacy') || text.contains('pharmacy'));

      case ReceiptTemplate.medplus:
        return merchant.contains('medplus') || text.contains('optival health');

      case ReceiptTemplate.thermalReceipt:
        return _detectThermalReceipt(text);

      case ReceiptTemplate.invoice:
        return text.contains('invoice') || text.contains('bill no');

      case ReceiptTemplate.generic:
        return true; // Fallback
    }
  }

  /// Detect if receipt is from thermal printer
  static bool _detectThermalReceipt(String text) {
    // Thermal receipts typically have:
    // - Short lines (40-50 chars)
    // - All caps
    // - Specific keywords
    final lines = text.split('\n');
    if (lines.length < 5) return false;

    int shortLinesCount = 0;
    int capsLinesCount = 0;

    for (final line in lines.take(10)) {
      if (line.trim().length < 50) shortLinesCount++;
      if (line == line.toUpperCase() && line.trim().length > 3) {
        capsLinesCount++;
      }
    }

    return shortLinesCount > 7 && capsLinesCount > 5;
  }

  /// Get template-specific parsing hints
  static TemplateHints getTemplateHints(ReceiptTemplate template) {
    switch (template) {
      case ReceiptTemplate.dmart:
        return TemplateHints(
          totalKeywords: ['total', 'net total', 'grand total'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.namePrice,
          currencyFormat: '₹',
          hasGST: true,
          hasTax: true,
        );

      case ReceiptTemplate.bigBazaar:
        return TemplateHints(
          totalKeywords: ['payable', 'grand total'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.namePrice,
          currencyFormat: 'Rs.',
          hasGST: true,
          hasTax: true,
        );

      case ReceiptTemplate.swiggy:
      case ReceiptTemplate.zomato:
        return TemplateHints(
          totalKeywords: ['order total', 'total', 'amount paid'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.nameQuantityPrice,
          currencyFormat: '₹',
          hasGST: true,
          hasTax: true,
          hasDeliveryFee: true,
        );

      case ReceiptTemplate.mcdonalds:
      case ReceiptTemplate.kfc:
      case ReceiptTemplate.dominos:
      case ReceiptTemplate.pizzaHut:
        return TemplateHints(
          totalKeywords: ['total', 'amount'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.nameQuantityPrice,
          currencyFormat: '₹',
          hasGST: true,
          hasTax: true,
        );

      case ReceiptTemplate.apollo:
      case ReceiptTemplate.medplus:
        return TemplateHints(
          totalKeywords: ['net amount', 'total', 'bill amount'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.nameQuantityPrice,
          currencyFormat: '₹',
          hasGST: true,
          hasTax: false,
          hasMRP: true,
        );

      case ReceiptTemplate.thermalReceipt:
        return TemplateHints(
          totalKeywords: ['total', 'grand total'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.namePrice,
          currencyFormat: 'Rs.',
          hasGST: false,
          hasTax: false,
        );

      case ReceiptTemplate.invoice:
        return TemplateHints(
          totalKeywords: ['invoice total', 'total amount', 'net amount'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.detailedInvoice,
          currencyFormat: 'INR',
          hasGST: true,
          hasTax: true,
        );

      case ReceiptTemplate.generic:
      default:
        return TemplateHints(
          totalKeywords: ['total', 'amount'],
          datePosition: TemplatePosition.top,
          itemsFormat: ItemsFormat.namePrice,
          currencyFormat: '₹',
          hasGST: false,
          hasTax: false,
        );
    }
  }
}

/// Quality metrics calculator for OCR results
class OCRQualityMetrics {
  /// Calculate comprehensive quality metrics
  static QualityReport calculateQuality(ExtractedReceipt receipt) {
    final scores = <String, double>{};
    final issues = <String>[];
    final suggestions = <String>[];

    // 1. Text extraction quality (0-20 points)
    final textScore = _scoreTextQuality(receipt.rawText);
    scores['text_extraction'] = textScore;
    if (textScore < 15) {
      issues.add('Low text extraction quality');
      suggestions.add('Retake photo with better lighting');
    }

    // 2. Data completeness (0-30 points)
    final completenessScore = _scoreCompleteness(receipt);
    scores['completeness'] = completenessScore;
    if (completenessScore < 20) {
      issues.add('Missing key information');
      suggestions.add('Ensure all fields are visible and clear');
    }

    // 3. Field confidence (0-25 points)
    final confidenceScore = _scoreFieldConfidence(receipt);
    scores['field_confidence'] = confidenceScore;
    if (confidenceScore < 18) {
      issues.add('Low confidence in extracted fields');
      suggestions.add('Try different lighting or angle');
    }

    // 4. Items extraction (0-15 points)
    final itemsScore = _scoreItems(receipt);
    scores['items_extraction'] = itemsScore;
    if (itemsScore < 10) {
      issues.add('Few or no items extracted');
      suggestions.add('Ensure items section is clearly visible');
    }

    // 5. Amount consistency (0-10 points)
    final consistencyScore = _scoreConsistency(receipt);
    scores['amount_consistency'] = consistencyScore;
    if (consistencyScore < 7) {
      issues.add('Total amount doesn\'t match items');
      suggestions.add('Verify the total amount manually');
    }

    // Calculate overall score
    final totalScore = scores.values.reduce((a, b) => a + b);
    final grade = _calculateGrade(totalScore);

    return QualityReport(
      overallScore: totalScore,
      grade: grade,
      scores: scores,
      issues: issues,
      suggestions: suggestions,
      passesValidation: totalScore >= 60,
    );
  }

  static double _scoreTextQuality(String text) {
    if (text.isEmpty) return 0;

    double score = 0;

    // Length (more text = better)
    if (text.length > 500) {
      score += 8;
    } else if (text.length > 200) {
      score += 5;
    } else if (text.length > 100) {
      score += 3;
    }

    // Readability (alphabetic ratio)
    final alphaCount = text.split('').where((c) => RegExp(r'[a-zA-Z]').hasMatch(c)).length;
    final alphaRatio = alphaCount / text.length;
    score += alphaRatio * 12;

    return score.clamp(0, 20);
  }

  static double _scoreCompleteness(ExtractedReceipt receipt) {
    double score = 0;

    // Merchant (10 points)
    if (receipt.merchantName != null && receipt.merchantName!.isNotEmpty) {
      score += 10;
    }

    // Date (8 points)
    if (receipt.date != null) {
      score += 8;
    }

    // Total (12 points)
    if (receipt.totalAmount != null && receipt.totalAmount! > 0) {
      score += 12;
    }

    return score.clamp(0, 30);
  }

  static double _scoreFieldConfidence(ExtractedReceipt receipt) {
    if (receipt.fieldConfidences.isEmpty) return 0;

    final avgConfidence = receipt.fieldConfidences.values
            .reduce((a, b) => a + b) /
        receipt.fieldConfidences.length;

    return (avgConfidence * 25).clamp(0, 25);
  }

  static double _scoreItems(ExtractedReceipt receipt) {
    if (receipt.items.isEmpty) return 0;

    double score = 0;

    // Number of items
    score += (receipt.items.length / 10 * 10).clamp(0, 10);

    // Items with categories
    final categorized = receipt.items
        .where((i) => i.category != null)
        .length;
    score += (categorized / receipt.items.length * 5).clamp(0, 5);

    return score.clamp(0, 15);
  }

  static double _scoreConsistency(ExtractedReceipt receipt) {
    if (receipt.totalAmount == null || receipt.items.isEmpty) return 5;

    final itemsTotal = receipt.items
        .map((i) => i.price * i.quantity)
        .reduce((a, b) => a + b);

    final difference = (receipt.totalAmount! - itemsTotal).abs();
    final tolerance = receipt.totalAmount! * 0.10; // 10% tolerance

    if (difference < 1) {
      return 10; // Perfect match
    } else if (difference < tolerance) {
      return 7; // Within tolerance
    } else {
      return 3; // Significant difference
    }
  }

  static String _calculateGrade(double score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B+';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 40) return 'D';
    return 'F';
  }
}

/// Receipt template types
enum ReceiptTemplate {
  dmart,
  bigBazaar,
  reliance,
  more,
  swiggy,
  zomato,
  mcdonalds,
  kfc,
  dominos,
  pizzaHut,
  apollo,
  medplus,
  thermalReceipt,
  invoice,
  generic,
}

/// Template parsing hints
class TemplateHints {
  final List<String> totalKeywords;
  final TemplatePosition datePosition;
  final ItemsFormat itemsFormat;
  final String currencyFormat;
  final bool hasGST;
  final bool hasTax;
  final bool hasDeliveryFee;
  final bool hasMRP;

  TemplateHints({
    required this.totalKeywords,
    required this.datePosition,
    required this.itemsFormat,
    required this.currencyFormat,
    this.hasGST = false,
    this.hasTax = false,
    this.hasDeliveryFee = false,
    this.hasMRP = false,
  });
}

enum TemplatePosition { top, bottom, middle }

enum ItemsFormat {
  namePrice,
  nameQuantityPrice,
  detailedInvoice,
}

/// Quality report for OCR result
class QualityReport {
  final double overallScore; // 0-100
  final String grade; // A+, A, B+, B, C, D, F
  final Map<String, double> scores; // Individual scores
  final List<String> issues; // Problems found
  final List<String> suggestions; // Improvement suggestions
  final bool passesValidation;

  QualityReport({
    required this.overallScore,
    required this.grade,
    required this.scores,
    required this.issues,
    required this.suggestions,
    required this.passesValidation,
  });

  Map<String, dynamic> toJson() => {
        'overall_score': overallScore,
        'grade': grade,
        'scores': scores,
        'issues': issues,
        'suggestions': suggestions,
        'passes_validation': passesValidation,
      };
}

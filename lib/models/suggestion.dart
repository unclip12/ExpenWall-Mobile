/// Model for autocomplete suggestions
class Suggestion {
  final String text;
  final String category;
  final int usageCount;
  final bool isLearned; // true if learned from user, false if common

  Suggestion({
    required this.text,
    required this.category,
    this.usageCount = 0,
    this.isLearned = false,
  });

  /// Create from Firestore document
  factory Suggestion.fromFirestore(Map<String, dynamic> data) {
    return Suggestion(
      text: data['text'] ?? '',
      category: data['category'] ?? 'general',
      usageCount: data['usageCount'] ?? 0,
      isLearned: data['isLearned'] ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'category': category,
      'usageCount': usageCount,
      'isLearned': isLearned,
    };
  }

  @override
  String toString() => text;
}

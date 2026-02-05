import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/suggestion.dart';
import '../constants/common_suggestions.dart';

class AutocompleteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for better performance
  List<Suggestion> _cachedSuggestions = [];
  DateTime? _lastCacheUpdate;

  /// Get suggestions based on user input
  /// Combines common suggestions + user's learned words
  Future<List<String>> getSuggestions(String query, {String? category}) async {
    if (query.isEmpty) return [];

    try {
      // Update cache if needed (every 5 minutes)
      if (_shouldUpdateCache()) {
        await _updateCache();
      }

      // Filter suggestions based on query
      final matches = _cachedSuggestions
          .where((s) {
            // Match category if provided
            if (category != null && s.category != category) {
              return false;
            }
            // Case-insensitive partial match
            return s.text.toLowerCase().contains(query.toLowerCase());
          })
          .toList();

      // Sort by usage frequency and relevance
      matches.sort((a, b) {
        // Exact matches first
        final aExact = a.text.toLowerCase().startsWith(query.toLowerCase());
        final bExact = b.text.toLowerCase().startsWith(query.toLowerCase());
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        // Then by frequency
        return b.usageCount.compareTo(a.usageCount);
      });

      // Return top 10 suggestions
      return matches.take(10).map((s) => s.text).toList();
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  /// Learn a new word from user input
  /// Saves to Firebase so it appears in future suggestions
  Future<void> learnWord(String word, {String? category}) async {
    if (word.trim().isEmpty) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final normalizedWord = word.trim().toLowerCase();

      // Check if word already exists in user's learned words
      final existingDoc = await _firestore
          .collection('learnedSuggestions')
          .doc(userId)
          .collection('words')
          .where('text', isEqualTo: normalizedWord)
          .limit(1)
          .get();

      if (existingDoc.docs.isNotEmpty) {
        // Word exists, increment usage count
        final docId = existingDoc.docs.first.id;
        await _firestore
            .collection('learnedSuggestions')
            .doc(userId)
            .collection('words')
            .doc(docId)
            .update({
          'usageCount': FieldValue.increment(1),
          'lastUsed': FieldValue.serverTimestamp(),
        });
      } else {
        // New word, add to database
        await _firestore
            .collection('learnedSuggestions')
            .doc(userId)
            .collection('words')
            .add({
          'text': normalizedWord,
          'originalCase': word.trim(), // Preserve user's casing
          'category': category ?? 'general',
          'usageCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUsed': FieldValue.serverTimestamp(),
        });
      }

      // Update cache
      await _updateCache();
    } catch (e) {
      print('Error learning word: $e');
    }
  }

  /// Check if cache should be updated
  bool _shouldUpdateCache() {
    if (_lastCacheUpdate == null) return true;
    final diff = DateTime.now().difference(_lastCacheUpdate!);
    return diff.inMinutes >= 5; // Update every 5 minutes
  }

  /// Update cache with latest suggestions
  Future<void> _updateCache() async {
    try {
      final userId = _auth.currentUser?.uid;
      final suggestions = <Suggestion>[];

      // Add common suggestions (pre-populated)
      suggestions.addAll(CommonSuggestions.all);

      // Add user's learned words if logged in
      if (userId != null) {
        final userWords = await _firestore
            .collection('learnedSuggestions')
            .doc(userId)
            .collection('words')
            .get();

        for (final doc in userWords.docs) {
          final data = doc.data();
          suggestions.add(Suggestion(
            text: data['originalCase'] ?? data['text'],
            category: data['category'] ?? 'general',
            usageCount: data['usageCount'] ?? 0,
            isLearned: true,
          ));
        }
      }

      _cachedSuggestions = suggestions;
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      print('Error updating cache: $e');
    }
  }

  /// Get suggestions for specific category
  Future<List<String>> getFoodSuggestions(String query) {
    return getSuggestions(query, category: 'food');
  }

  Future<List<String>> getMerchantSuggestions(String query) {
    return getSuggestions(query, category: 'merchant');
  }

  Future<List<String>> getCategorySuggestions(String query) {
    return getSuggestions(query, category: 'category');
  }

  /// Force refresh cache
  Future<void> refreshCache() async {
    await _updateCache();
  }

  /// Clear user's learned words (for settings)
  Future<void> clearLearnedWords() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final docs = await _firestore
          .collection('learnedSuggestions')
          .doc(userId)
          .collection('words')
          .get();

      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _updateCache();
    } catch (e) {
      print('Error clearing learned words: $e');
    }
  }
}

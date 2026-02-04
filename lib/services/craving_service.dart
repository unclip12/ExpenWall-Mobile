import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/craving.dart';

class CravingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get cravings collection reference for a user
  CollectionReference<Map<String, dynamic>> _getCravingsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cravings');
  }

  /// Add a new craving
  Future<String> addCraving(Craving craving) async {
    try {
      final docRef = await _getCravingsCollection(craving.userId)
          .add(craving.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add craving: $e');
    }
  }

  /// Update an existing craving
  Future<void> updateCraving(Craving craving) async {
    try {
      await _getCravingsCollection(craving.userId)
          .doc(craving.id)
          .update(craving.toFirestore());
    } catch (e) {
      throw Exception('Failed to update craving: $e');
    }
  }

  /// Delete a craving
  Future<void> deleteCraving(String userId, String cravingId) async {
    try {
      await _getCravingsCollection(userId).doc(cravingId).delete();
    } catch (e) {
      throw Exception('Failed to delete craving: $e');
    }
  }

  /// Get a single craving by ID
  Future<Craving?> getCraving(String userId, String cravingId) async {
    try {
      final doc = await _getCravingsCollection(userId).doc(cravingId).get();
      if (!doc.exists) return null;
      return Craving.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get craving: $e');
    }
  }

  /// Stream all cravings for a user (real-time)
  Stream<List<Craving>> streamCravings(String userId) {
    return _getCravingsCollection(userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Craving.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all cravings for a user (one-time fetch)
  Future<List<Craving>> getCravings(String userId) async {
    try {
      final snapshot = await _getCravingsCollection(userId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Craving.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get cravings: $e');
    }
  }

  /// Get cravings within a date range
  Future<List<Craving>> getCravingsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _getCravingsCollection(userId)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Craving.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get cravings by date range: $e');
    }
  }

  /// Get cravings by status
  Future<List<Craving>> getCravingsByStatus(
    String userId,
    CravingStatus status,
  ) async {
    try {
      final snapshot = await _getCravingsCollection(userId)
          .where('status', isEqualTo: status.name)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Craving.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get cravings by status: $e');
    }
  }

  /// Get cravings by merchant
  Future<List<Craving>> getCravingsByMerchant(
    String userId,
    String merchant,
  ) async {
    try {
      final snapshot = await _getCravingsCollection(userId)
          .where('merchant', isEqualTo: merchant)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Craving.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get cravings by merchant: $e');
    }
  }

  /// Get analytics for user's cravings
  Future<CravingAnalytics> getAnalytics(String userId) async {
    try {
      final cravings = await getCravings(userId);
      return CravingAnalytics.fromCravings(cravings);
    } catch (e) {
      throw Exception('Failed to get craving analytics: $e');
    }
  }

  /// Stream analytics (real-time)
  Stream<CravingAnalytics> streamAnalytics(String userId) {
    return streamCravings(userId)
        .map((cravings) => CravingAnalytics.fromCravings(cravings));
  }

  /// Get resisted count for today
  Future<int> getTodayResistedCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _getCravingsCollection(userId)
          .where('status', isEqualTo: CravingStatus.resisted.name)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.size;
    } catch (e) {
      throw Exception('Failed to get today resisted count: $e');
    }
  }

  /// Get gave in count for today
  Future<int> getTodayGaveInCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _getCravingsCollection(userId)
          .where('status', isEqualTo: CravingStatus.gaveIn.name)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.size;
    } catch (e) {
      throw Exception('Failed to get today gave in count: $e');
    }
  }

  /// Get total amount spent in current month
  Future<double> getMonthlySpending(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final cravings = await getCravingsByDateRange(
        userId,
        startOfMonth,
        endOfMonth,
      );

      final double total = cravings
          .where((c) => c.gaveIn)
          .fold<double>(0.0, (double sum, Craving c) => sum + c.totalAmount);
      
      return total;
    } catch (e) {
      throw Exception('Failed to get monthly spending: $e');
    }
  }
}

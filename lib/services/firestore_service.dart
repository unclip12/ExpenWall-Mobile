import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/merchant_rule.dart';
import '../models/product.dart';
import '../models/budget.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== TRANSACTIONS ====================
  
  Stream<List<Transaction>> subscribeToTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _db.collection('transactions').add(transaction.toJson());
  }

  Future<void> addTransactionsBatch(List<Transaction> transactions) async {
    final batch = _db.batch();
    for (var tx in transactions) {
      final ref = _db.collection('transactions').doc();
      batch.set(ref, tx.toJson());
    }
    await batch.commit();
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _db.collection('transactions').doc(id).update(data);
  }

  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }

  // ==================== MERCHANT RULES ====================
  
  Stream<List<MerchantRule>> subscribeToRules(String userId) {
    return _db
        .collection('merchantRules')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MerchantRule.fromFirestore(doc)).toList());
  }

  Future<void> addMerchantRule(MerchantRule rule) async {
    await _db.collection('merchantRules').add(rule.toJson());
  }

  Future<void> deleteMerchantRule(String id) async {
    await _db.collection('merchantRules').doc(id).delete();
  }

  // ==================== WALLETS ====================
  
  Stream<List<Wallet>> subscribeToWallets(String userId) {
    return _db
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Wallet.fromFirestore(doc)).toList());
  }

  Future<void> addWallet(Wallet wallet) async {
    await _db.collection('wallets').add(wallet.toJson());
  }

  Future<void> deleteWallet(String id) async {
    await _db.collection('wallets').doc(id).delete();
  }

  // ==================== PRODUCTS ====================
  
  Stream<List<Product>> subscribeToProducts(String userId) {
    return _db
        .collection('products')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // ==================== BUDGETS ====================
  
  Stream<List<Budget>> subscribeToBudgets(String userId) {
    return _db
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList());
  }

  Future<void> addBudget(Budget budget) async {
    await _db.collection('budgets').add(budget.toJson());
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    await _db.collection('budgets').doc(id).update(data);
  }

  Future<void> deleteBudget(String id) async {
    await _db.collection('budgets').doc(id).delete();
  }

  // ==================== USER PROFILE ====================
  
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('userProfiles').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> saveUserTheme(String userId, String theme) async {
    await _db.collection('userProfiles').doc(userId).set({
      'theme': theme,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

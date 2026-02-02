import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import '../models/merchant_rule.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // TRANSACTIONS
  Stream<List<Transaction>> subscribeToTransactions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addTransaction(Transaction transaction) async {
    final userId = transaction.userId ?? '';
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toFirestore());
  }

  Future<void> updateTransaction(String userId, Transaction transaction) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String transactionId) async {
    // Note: You'll need to pass userId or store it in state
    // For now, this is a placeholder
    throw UnimplementedError('Delete requires userId context');
  }

  // MERCHANT RULES
  Stream<List<MerchantRule>> subscribeToRules(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('merchantRules')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MerchantRule.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addRule(String userId, MerchantRule rule) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('merchantRules')
        .doc(rule.id)
        .set(rule.toFirestore());
  }

  // WALLETS
  Stream<List<Wallet>> subscribeToWallets(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Wallet.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addWallet(String userId, Wallet wallet) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(wallet.id)
        .set(wallet.toFirestore());
  }

  // BUDGETS
  Stream<List<Budget>> subscribeToBudgets(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addBudget(Budget budget) async {
    final userId = budget.userId ?? '';
    await _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budget.id)
        .set(budget.toFirestore());
  }

  Future<void> deleteBudget(String budgetId) async {
    // Note: Requires userId context
    throw UnimplementedError('Delete requires userId context');
  }

  // PRODUCTS
  Stream<List<Product>> subscribeToProducts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}

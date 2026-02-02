import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import '../models/product.dart';
import '../models/wallet.dart';
import '../models/merchant_rule.dart';

class LocalStorageService {
  static const String _transactionsFile = 'transactions';
  static const String _budgetsFile = 'budgets';
  static const String _productsFile = 'products';
  static const String _walletsFile = 'wallets';
  static const String _rulesFile = 'rules';
  static const String _pendingOpsFile = 'pending_operations';
  
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _userIdKey = 'cached_user_id';

  // Get app documents directory
  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  // Get file for user-specific data
  Future<File> _getUserFile(String userId, String filename) async {
    final dir = await _getStorageDirectory();
    return File('${dir.path}/${filename}_$userId.json');
  }

  // TRANSACTIONS
  Future<void> saveTransactions(String userId, List<models.Transaction> transactions) async {
    try {
      final file = await _getUserFile(userId, _transactionsFile);
      final jsonList = transactions.map((t) => {
        'id': t.id,
        'userId': t.userId,
        'merchant': t.merchant,
        'merchantEmoji': t.merchantEmoji,
        'date': t.date.toIso8601String(),
        'time': t.time,
        'amount': t.amount,
        'currency': t.currency,
        'category': t.category.label,
        'subcategory': t.subcategory,
        'type': t.type.name,
        'walletId': t.walletId,
        'items': t.items?.map((item) => {
          'name': item.name,
          'brand': item.brand,
          'price': item.price,
          'quantity': item.quantity,
          'weight': item.weight,
          'weightUnit': item.weightUnit?.name,
          'mrp': item.mrp,
          'discount': item.discount,
          'tax': item.tax,
          'pricePerUnit': item.pricePerUnit,
        }).toList(),
        'notes': t.notes,
        'tags': t.tags,
        'isRecurring': t.isRecurring,
        'recurringId': t.recurringId,
      }).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
      await _updateLastSync();
    } catch (e) {
      print('Error saving transactions to local storage: $e');
    }
  }

  Future<List<models.Transaction>> loadTransactions(String userId) async {
    try {
      final file = await _getUserFile(userId, _transactionsFile);
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((json) => models.Transaction(
        id: json['id'],
        userId: json['userId'],
        merchant: json['merchant'] ?? '',
        merchantEmoji: json['merchantEmoji'],
        date: DateTime.parse(json['date']),
        time: json['time'],
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] ?? 'INR',
        category: models.Category.values.firstWhere(
          (e) => e.label == json['category'],
          orElse: () => models.Category.other,
        ),
        subcategory: json['subcategory'],
        type: models.TransactionType.values.byName(json['type']),
        walletId: json['walletId'],
        items: (json['items'] as List?)?.map((item) => models.TransactionItem(
          name: item['name'],
          brand: item['brand'],
          price: (item['price'] as num).toDouble(),
          quantity: item['quantity'],
          weight: item['weight']?.toDouble(),
          weightUnit: item['weightUnit'] != null 
              ? models.UnitType.values.byName(item['weightUnit']) 
              : null,
          mrp: item['mrp']?.toDouble(),
          discount: item['discount']?.toDouble(),
          tax: item['tax']?.toDouble(),
          pricePerUnit: item['pricePerUnit']?.toDouble(),
        )).toList(),
        notes: json['notes'],
        tags: (json['tags'] as List?)?.cast<String>(),
        isRecurring: json['isRecurring'] ?? false,
        recurringId: json['recurringId'],
      )).toList();
    } catch (e) {
      print('Error loading transactions from local storage: $e');
      return [];
    }
  }

  // BUDGETS
  Future<void> saveBudgets(String userId, List<Budget> budgets) async {
    try {
      final file = await _getUserFile(userId, _budgetsFile);
      final jsonList = budgets.map((b) => {
        'id': b.id,
        'userId': b.userId,
        'category': b.category.label,
        'amount': b.amount,
        'period': b.period,
      }).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
      await _updateLastSync();
    } catch (e) {
      print('Error saving budgets to local storage: $e');
    }
  }

  Future<List<Budget>> loadBudgets(String userId) async {
    try {
      final file = await _getUserFile(userId, _budgetsFile);
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((json) => Budget(
        id: json['id'],
        userId: json['userId'],
        category: models.Category.values.firstWhere(
          (e) => e.label == json['category'],
          orElse: () => models.Category.other,
        ),
        amount: (json['amount'] as num).toDouble(),
        period: json['period'],
      )).toList();
    } catch (e) {
      print('Error loading budgets from local storage: $e');
      return [];
    }
  }

  // PRODUCTS
  Future<void> saveProducts(String userId, List<Product> products) async {
    try {
      final file = await _getUserFile(userId, _productsFile);
      final jsonList = products.map((p) => p.toFirestore()).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
      await _updateLastSync();
    } catch (e) {
      print('Error saving products to local storage: $e');
    }
  }

  Future<List<Product>> loadProducts(String userId) async {
    try {
      final file = await _getUserFile(userId, _productsFile);
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((json) => Product.fromFirestore(json, json['id'])).toList();
    } catch (e) {
      print('Error loading products from local storage: $e');
      return [];
    }
  }

  // WALLETS
  Future<void> saveWallets(String userId, List<Wallet> wallets) async {
    try {
      final file = await _getUserFile(userId, _walletsFile);
      final jsonList = wallets.map((w) => w.toFirestore()).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
      await _updateLastSync();
    } catch (e) {
      print('Error saving wallets to local storage: $e');
    }
  }

  Future<List<Wallet>> loadWallets(String userId) async {
    try {
      final file = await _getUserFile(userId, _walletsFile);
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // Wallets need proper DocumentSnapshot parsing
      // For now, return empty - will fix when Wallet model is updated
      return [];
    } catch (e) {
      print('Error loading wallets from local storage: $e');
      return [];
    }
  }

  // MERCHANT RULES
  Future<void> saveRules(String userId, List<MerchantRule> rules) async {
    try {
      final file = await _getUserFile(userId, _rulesFile);
      final jsonList = rules.map((r) => r.toFirestore()).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
      await _updateLastSync();
    } catch (e) {
      print('Error saving rules to local storage: $e');
    }
  }

  Future<List<MerchantRule>> loadRules(String userId) async {
    try {
      final file = await _getUserFile(userId, _rulesFile);
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // MerchantRules need proper DocumentSnapshot parsing
      // For now, return empty - will fix when MerchantRule model is updated
      return [];
    } catch (e) {
      print('Error loading rules from local storage: $e');
      return [];
    }
  }

  // PENDING OPERATIONS QUEUE
  Future<void> addPendingOperation(String userId, Map<String, dynamic> operation) async {
    try {
      final file = await _getUserFile(userId, _pendingOpsFile);
      List<dynamic> operations = [];
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        operations = jsonDecode(jsonString);
      }
      
      operations.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
        ...operation,
      });
      
      await file.writeAsString(jsonEncode(operations));
    } catch (e) {
      print('Error adding pending operation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingOperations(String userId) async {
    try {
      final file = await _getUserFile(userId, _pendingOpsFile);
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> operations = jsonDecode(jsonString);
      return operations.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting pending operations: $e');
      return [];
    }
  }

  Future<void> clearPendingOperation(String userId, String operationId) async {
    try {
      final file = await _getUserFile(userId, _pendingOpsFile);
      if (!await file.exists()) return;
      
      final jsonString = await file.readAsString();
      List<dynamic> operations = jsonDecode(jsonString);
      
      operations.removeWhere((op) => op['id'] == operationId);
      
      await file.writeAsString(jsonEncode(operations));
    } catch (e) {
      print('Error clearing pending operation: $e');
    }
  }

  // METADATA
  Future<void> _updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> cacheUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // CLEAR ALL LOCAL DATA (for logout)
  Future<void> clearAllLocalData(String userId) async {
    try {
      final files = [
        _transactionsFile,
        _budgetsFile,
        _productsFile,
        _walletsFile,
        _rulesFile,
        _pendingOpsFile,
      ];
      
      for (final filename in files) {
        final file = await _getUserFile(userId, filename);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }
}

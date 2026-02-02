// Extension to LocalStorageService for Split Bills
// Add these methods to lib/services/local_storage_service.dart

import 'dart:convert';
import '../models/split_bill.dart';

// Add to LocalStorageService class:

/*
  static const String _splitBillsFile = 'split_bills';

  // SPLIT BILLS
  Future<void> saveSplitBills(String userId, List<SplitBill> bills) async {
    try {
      final file = await _getUserFile(userId, _splitBillsFile);
      final jsonList = bills.map((b) => b.toJson()).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
      await _updateLastSync();
    } catch (e) {
      print('Error saving split bills to local storage: $e');
    }
  }

  Future<List<SplitBill>> loadSplitBills(String userId) async {
    try {
      final file = await _getUserFile(userId, _splitBillsFile);
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((json) => SplitBill.fromJson(json)).toList();
    } catch (e) {
      print('Error loading split bills from local storage: $e');
      return [];
    }
  }
*/

// Also add _splitBillsFile to the clearAllLocalData method's files list

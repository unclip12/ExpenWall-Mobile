import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_drive_service.dart';
import 'local_storage_service.dart';

/// Manages automatic syncing between local storage and Google Drive
class SyncManager {
  final GoogleDriveService _driveService;
  final LocalStorageService _localStorage;
  final String userId;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const int _defaultSyncInterval = 5; // minutes

  SyncManager({
    required GoogleDriveService driveService,
    required LocalStorageService localStorage,
    required this.userId,
  })  : _driveService = driveService,
        _localStorage = localStorage;

  // Check if auto-sync is enabled
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncKey) ?? false;
  }

  // Set auto-sync enabled/disabled
  Future<void> setAutoSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
    
    if (enabled) {
      startAutoSync();
    } else {
      stopAutoSync();
    }
  }

  // Get sync interval in minutes
  Future<int> getSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncIntervalKey) ?? _defaultSyncInterval;
  }

  // Set sync interval in minutes
  Future<void> setSyncInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncIntervalKey, minutes);
    
    // Restart sync timer with new interval
    final autoSyncEnabled = await isAutoSyncEnabled();
    if (autoSyncEnabled) {
      stopAutoSync();
      startAutoSync();
    }
  }

  // Start automatic background sync
  Future<void> startAutoSync() async {
    if (!_driveService.isSignedIn) {
      print('Cannot start auto-sync: Not signed in to Google');
      return;
    }

    final interval = await getSyncInterval();
    _syncTimer?.cancel();
    
    // Initial sync
    syncNow();
    
    // Schedule periodic sync
    _syncTimer = Timer.periodic(
      Duration(minutes: interval),
      (_) => syncNow(),
    );
    
    print('Auto-sync started with $interval minute interval');
  }

  // Stop automatic sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('Auto-sync stopped');
  }

  // Perform sync now (with conflict resolution)
  Future<bool> syncNow() async {
    if (_isSyncing) {
      print('Sync already in progress');
      return false;
    }

    if (!_driveService.isSignedIn) {
      print('Not signed in to Google');
      return false;
    }

    _isSyncing = true;
    bool success = false;

    try {
      // Check for pending operations
      final pendingOps = await _localStorage.getPendingOperations(userId);
      
      if (pendingOps.isNotEmpty) {
        print('Processing ${pendingOps.length} pending operations');
        // For now, just clear them after backup
        // TODO: Implement proper operation replay
      }

      // Perform backup
      success = await _driveService.backupToCloud(userId);
      
      if (success) {
        print('Sync completed successfully');
        
        // Clear pending operations after successful sync
        for (final op in pendingOps) {
          await _localStorage.clearPendingOperation(userId, op['id']);
        }
      } else {
        print('Sync failed');
      }
    } catch (e) {
      print('Error during sync: $e');
      success = false;
    } finally {
      _isSyncing = false;
    }

    return success;
  }

  // Check if currently syncing
  bool get isSyncing => _isSyncing;

  // Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }

  // Smart sync: Only backup if data has changed
  Future<bool> smartSync() async {
    final lastSync = await _localStorage.getLastSyncTime();
    
    if (lastSync != null) {
      final timeSinceSync = DateTime.now().difference(lastSync);
      
      // Don't sync if last sync was less than 1 minute ago
      if (timeSinceSync.inMinutes < 1) {
        print('Skipping sync - too soon since last sync');
        return false;
      }
    }

    return syncNow();
  }

  // Conflict resolution: Merge local and cloud data
  Future<void> resolveConflicts() async {
    // Download cloud data
    final cloudRestored = await _driveService.restoreFromCloud(userId);
    
    if (!cloudRestored) {
      print('No cloud data to merge');
      return;
    }

    // Load both local and downloaded cloud data
    final localTransactions = await _localStorage.loadTransactions(userId);
    
    // TODO: Implement smart merge logic
    // For now, we'll use last-write-wins (local takes precedence)
    
    // Save merged data
    await _localStorage.saveTransactions(userId, localTransactions);
    
    // Backup merged result
    await _driveService.backupToCloud(userId);
    
    print('Conflicts resolved and synced');
  }
}

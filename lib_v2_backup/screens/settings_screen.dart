import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/google_drive_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_manager.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GoogleDriveService _driveService = GoogleDriveService();
  final LocalStorageService _localStorage = LocalStorageService();
  late SyncManager _syncManager;
  
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isSignedIn = false;
  bool _autoSyncEnabled = false;
  String? _userEmail;
  DateTime? _lastBackupTime;
  String _userId = 'local_user';
  int _syncInterval = 5;

  @override
  void initState() {
    super.initState();
    _syncManager = SyncManager(
      driveService: _driveService,
      localStorage: _localStorage,
      userId: _userId,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _syncManager.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await _driveService.init();
    final cachedUserId = await _localStorage.getCachedUserId();
    if (cachedUserId != null) {
      _userId = cachedUserId;
      _syncManager = SyncManager(
        driveService: _driveService,
        localStorage: _localStorage,
        userId: _userId,
      );
    }
    
    final autoSync = await _syncManager.isAutoSyncEnabled();
    final interval = await _syncManager.getSyncInterval();
    
    setState(() {
      _isSignedIn = _driveService.isSignedIn;
      _userEmail = _driveService.userEmail;
      _autoSyncEnabled = autoSync;
      _syncInterval = interval;
      _isLoading = false;
    });

    if (_isSignedIn) {
      _loadLastBackupTime();
      if (_autoSyncEnabled) {
        _syncManager.startAutoSync();
      }
    }
  }

  Future<void> _loadLastBackupTime() async {
    final lastBackup = await _driveService.getLastBackupTime();
    setState(() {
      _lastBackupTime = lastBackup;
    });
  }

  Future<void> _signInToGoogle() async {
    setState(() => _isLoading = true);
    
    final success = await _driveService.signIn();
    
    if (success) {
      setState(() {
        _isSignedIn = true;
        _userEmail = _driveService.userEmail;
        _isLoading = false;
      });
      
      _showSnackBar('Signed in successfully!', Colors.green);
      _loadLastBackupTime();
    } else {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to sign in', Colors.red);
    }
  }

  Future<void> _signOut() async {
    await _syncManager.setAutoSync(false);
    await _driveService.signOut();
    setState(() {
      _isSignedIn = false;
      _userEmail = null;
      _lastBackupTime = null;
      _autoSyncEnabled = false;
    });
    _showSnackBar('Signed out', Colors.grey);
  }

  Future<void> _toggleAutoSync(bool enabled) async {
    await _syncManager.setAutoSync(enabled);
    setState(() {
      _autoSyncEnabled = enabled;
    });
    
    if (enabled) {
      _showSnackBar('Auto-sync enabled', Colors.green);
      _syncManager.startAutoSync();
    } else {
      _showSnackBar('Auto-sync disabled', Colors.grey);
    }
  }

  Future<void> _changeSyncInterval() async {
    final intervals = [1, 5, 10, 15, 30, 60];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((minutes) {
            return RadioListTile<int>(
              title: Text('$minutes ${minutes == 1 ? 'minute' : 'minutes'}'),
              value: minutes,
              groupValue: _syncInterval,
              onChanged: (value) async {
                if (value != null) {
                  await _syncManager.setSyncInterval(value);
                  setState(() => _syncInterval = value);
                  Navigator.pop(context);
                  _showSnackBar('Sync interval updated', Colors.green);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _backupNow() async {
    setState(() => _isSyncing = true);
    
    final success = await _syncManager.syncNow();
    
    setState(() => _isSyncing = false);
    
    if (success) {
      _showSnackBar('Backup successful!', Colors.green);
      _loadLastBackupTime();
    } else {
      _showSnackBar('Backup failed', Colors.red);
    }
  }

  Future<void> _restoreNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Cloud?'),
        content: const Text(
          'This will replace your current local data with the cloud backup. '
          'Your current data will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSyncing = true);
    
    final success = await _driveService.restoreFromCloud(_userId);
    
    setState(() => _isSyncing = false);
    
    if (success) {
      _showSnackBar('Restore successful! Restart app to see changes.', Colors.green);
    } else {
      _showSnackBar('Restore failed', Colors.red);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');
      
      // Collect all data files
      final files = [
        'transactions_$_userId.json',
        'budgets_$_userId.json',
        'products_$_userId.json',
      ];
      
      Map<String, dynamic> exportData = {
        'version': '2.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'userId': _userId,
      };
      
      for (final fileName in files) {
        final file = File('${cacheDir.path}/$fileName');
        if (await file.exists()) {
          final content = await file.readAsString();
          final key = fileName.split('_').first;
          exportData[key] = jsonDecode(content);
        }
      }
      
      // Create export file
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFileName = 'ExpenWall_Backup_$timestamp.json';
      final exportFile = File('${appDir.path}/$exportFileName');
      await exportFile.writeAsString(jsonEncode(exportData));
      
      // Share the file
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        text: 'ExpenWall Backup - $timestamp',
      );
      
      setState(() => _isLoading = false);
      _showSnackBar('Data exported successfully', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Export failed: $e', Colors.red);
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) return;
      
      setState(() => _isLoading = true);
      
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final importData = jsonDecode(content);
      
      // Validate format
      if (importData['version'] == null || importData['exportDate'] == null) {
        throw Exception('Invalid backup file format');
      }
      
      // Save imported data
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      if (importData['transactions'] != null) {
        final transFile = File('${cacheDir.path}/transactions_$_userId.json');
        await transFile.writeAsString(jsonEncode(importData['transactions']));
      }
      
      if (importData['budgets'] != null) {
        final budgetFile = File('${cacheDir.path}/budgets_$_userId.json');
        await budgetFile.writeAsString(jsonEncode(importData['budgets']));
      }
      
      if (importData['products'] != null) {
        final prodFile = File('${cacheDir.path}/products_$_userId.json');
        await prodFile.writeAsString(jsonEncode(importData['products']));
      }
      
      setState(() => _isLoading = false);
      _showSnackBar('Import successful! Restart app to see changes.', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Import failed: $e', Colors.red);
    }
  }

  Future<void> _deleteCloudData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cloud Backup?'),
        content: const Text(
          'This will permanently delete your backup from Google Drive. '
          'Your local data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    final success = await _driveService.deleteCloudBackup();
    
    setState(() => _isLoading = false);
    
    if (success) {
      setState(() => _lastBackupTime = null);
      _showSnackBar('Cloud backup deleted', Colors.grey);
    } else {
      _showSnackBar('Failed to delete backup', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        
        // Cloud Backup Section
        _buildSectionTitle('Cloud Backup'),
        const SizedBox(height: 12),
        
        if (!_isSignedIn)
          _buildSignInCard()
        else
          _buildCloudBackupCard(),
        
        const SizedBox(height: 32),
        
        // Manual Backup Section
        _buildSectionTitle('Manual Backup'),
        const SizedBox(height: 12),
        _buildManualBackupCard(),
        
        const SizedBox(height: 32),
        
        // About Section
        _buildSectionTitle('About'),
        const SizedBox(height: 12),
        _buildAboutCard(),
        
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSignInCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.purpleGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Backup to Google Drive',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in with your Google account to backup your data to your own Google Drive. Your data stays private!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _signInToGoogle,
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudBackupCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
                child: Icon(
                  _autoSyncEnabled ? Icons.cloud_sync : Icons.cloud_done,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userEmail ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Auto-sync toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sync,
                  size: 20,
                  color: _autoSyncEnabled ? AppTheme.primaryPurple : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auto-sync',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _autoSyncEnabled
                            ? 'Every $_syncInterval ${_syncInterval == 1 ? 'minute' : 'minutes'}'
                            : 'Disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_autoSyncEnabled)
                  TextButton(
                    onPressed: _changeSyncInterval,
                    child: const Text('Change'),
                  ),
                Switch(
                  value: _autoSyncEnabled,
                  onChanged: _toggleAutoSync,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Last Backup Time
          if (_lastBackupTime != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last backup: ${_formatBackupTime(_lastBackupTime!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _backupNow,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload, size: 18),
                  label: Text(_isSyncing ? 'Syncing...' : 'Backup Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSyncing ? null : _restoreNow,
                  icon: const Icon(Icons.cloud_download, size: 18),
                  label: const Text('Restore'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Delete Cloud Backup
          Center(
            child: TextButton.icon(
              onPressed: _deleteCloudData,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Cloud Backup'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualBackupCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export/Import Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Backup your data to a file or restore from a previous backup.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importData,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Import'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ExpenWall',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 2.0.0 (Offline-First)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Smart expense tracking with complete privacy. Your data stays on your device and optionally syncs to your own Google Drive.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBackupTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(time);
    }
  }
}

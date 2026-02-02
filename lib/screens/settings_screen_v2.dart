import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/google_drive_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_manager.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class SettingsScreenV2 extends StatefulWidget {
  const SettingsScreenV2({super.key});

  @override
  State<SettingsScreenV2> createState() => _SettingsScreenV2State();
}

class _SettingsScreenV2State extends State<SettingsScreenV2> {
  final GoogleDriveService _driveService = GoogleDriveService();
  final LocalStorageService _localStorage = LocalStorageService();
  final ThemeService _themeService = ThemeService();
  late SyncManager _syncManager;
  
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isSignedIn = false;
  bool _autoSyncEnabled = false;
  bool _isDarkMode = false;
  String? _userEmail;
  DateTime? _lastBackupTime;
  String _userId = 'local_user';
  int _syncInterval = 5;
  AppThemeType _currentTheme = AppThemeType.midnightPurple;

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
    final isDark = await _themeService.isDarkMode();
    final theme = await _themeService.getTheme();
    
    setState(() {
      _isSignedIn = _driveService.isSignedIn;
      _userEmail = _driveService.userEmail;
      _autoSyncEnabled = autoSync;
      _syncInterval = interval;
      _isDarkMode = isDark;
      _currentTheme = theme;
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

  // Toggle dark mode
  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await MyApp.of(context)?.toggleDarkMode(value);
    _showSnackBar(
      value ? 'Dark mode enabled' : 'Light mode enabled',
      Colors.grey,
    );
  }

  // Change theme
  Future<void> _changeTheme(AppThemeType theme) async {
    setState(() => _currentTheme = theme);
    await MyApp.of(context)?.changeTheme(theme);
    final themeName = ThemeService.themeMetadata[theme]!['name'];
    _showSnackBar('Theme changed to $themeName', Colors.green);
  }

  // Show theme selector dialog
  Future<void> _showThemeSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose Your Theme',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: AppThemeType.values.length,
                  itemBuilder: (context, index) {
                    final theme = AppThemeType.values[index];
                    final metadata = ThemeService.themeMetadata[theme]!;
                    final isSelected = theme == _currentTheme;

                    return GestureDetector(
                      onTap: () {
                        _changeTheme(theme);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              metadata['primaryColor'],
                              (metadata['primaryColor'] as Color).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (metadata['primaryColor'] as Color).withOpacity(0.4),
                              blurRadius: isSelected ? 20 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background icon
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Icon(
                                metadata['icon'],
                                size: 120,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    metadata['icon'],
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    metadata['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    metadata['description'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selected indicator
                            if (isSelected)
                              const Positioned(
                                top: 12,
                                right: 12,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFileName = 'ExpenWall_Backup_$timestamp.json';
      final exportFile = File('${appDir.path}/$exportFileName');
      await exportFile.writeAsString(jsonEncode(exportData));
      
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
      
      if (importData['version'] == null || importData['exportDate'] == null) {
        throw Exception('Invalid backup file format');
      }
      
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
        
        // Appearance Section
        _buildSectionTitle('Appearance'),
        const SizedBox(height: 12),
        _buildAppearanceCard(),
        const SizedBox(height: 32),
        
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

  Widget _buildAppearanceCard() {
    final currentThemeMeta = ThemeService.themeMetadata[_currentTheme]!;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark Mode Toggle
          Row(
            children: [
              Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isDarkMode ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ],
          ),
          const Divider(height: 32),
          
          // Theme Selector
          const Text(
            'App Theme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showThemeSelector,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    currentThemeMeta['primaryColor'],
                    (currentThemeMeta['primaryColor'] as Color).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    currentThemeMeta['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentThemeMeta['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          currentThemeMeta['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to choose from 10 beautiful themes',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
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
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
              ),
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
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Icon(
                  _autoSyncEnabled ? Icons.cloud_sync : Icons.cloud_done,
                  color: Theme.of(context).colorScheme.primary,
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
                  color: _autoSyncEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
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
            'Version 2.3.1 (Split Bills Update)',
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

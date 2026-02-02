import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import '../services/local_storage_service.dart';
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
  
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isSignedIn = false;
  String? _userEmail;
  DateTime? _lastBackupTime;
  String _userId = 'local_user';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _driveService.init();
    final cachedUserId = await _localStorage.getCachedUserId();
    if (cachedUserId != null) {
      _userId = cachedUserId;
    }
    
    setState(() {
      _isSignedIn = _driveService.isSignedIn;
      _userEmail = _driveService.userEmail;
      _isLoading = false;
    });

    if (_isSignedIn) {
      _loadLastBackupTime();
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
    await _driveService.signOut();
    setState(() {
      _isSignedIn = false;
      _userEmail = null;
      _lastBackupTime = null;
    });
    _showSnackBar('Signed out', Colors.grey);
  }

  Future<void> _backupNow() async {
    setState(() => _isSyncing = true);
    
    final success = await _driveService.backupToCloud(_userId);
    
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
                child: const Icon(
                  Icons.cloud_done,
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
          const SizedBox(height: 20),
          
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
          TextButton.icon(
            onPressed: _deleteCloudData,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete Cloud Backup'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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

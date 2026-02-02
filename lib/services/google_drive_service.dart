import 'dart:io';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'local_storage_service.dart';

/// Google Drive service for backing up user data to their own Google Drive
class GoogleDriveService {
  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope, // Access to files created by this app
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  final LocalStorageService _localStorageService = LocalStorageService();
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // Check if user is signed in
  bool get isSignedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;

  // Initialize and check existing sign-in
  Future<void> init() async {
    _currentUser = await _googleSignIn.signInSilently();
    if (_currentUser != null) {
      await _initDriveApi();
    }
  }

  // Initialize Drive API
  Future<void> _initDriveApi() async {
    if (_currentUser == null) return;

    try {
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient != null) {
        _driveApi = drive.DriveApi(authClient);
      }
    } catch (e) {
      print('Error initializing Drive API: $e');
    }
  }

  // Sign in with Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  // Get or create app folder in Google Drive
  Future<String?> _getAppFolderId() async {
    if (_driveApi == null) return null;

    try {
      // Search for existing folder
      final folderQuery = "name='ExpenWall_Backup' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final folderList = await _driveApi!.files.list(
        q: folderQuery,
        spaces: 'drive',
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }

      // Create new folder
      final folder = drive.File();
      folder.name = 'ExpenWall_Backup';
      folder.mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Error getting/creating folder: $e');
      return null;
    }
  }

  // Upload a file to Google Drive
  Future<bool> _uploadFile(String fileName, String content, String? folderId) async {
    if (_driveApi == null) return false;

    try {
      // Check if file already exists
      String query = "name='$fileName' and trashed=false";
      if (folderId != null) {
        query += " and '$folderId' in parents";
      }

      final existingFiles = await _driveApi!.files.list(q: query, spaces: 'drive');

      final fileMetadata = drive.File();
      fileMetadata.name = fileName;
      if (folderId != null) {
        fileMetadata.parents = [folderId];
      }

      final media = drive.Media(
        Stream.value(utf8.encode(content)),
        content.length,
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file
        final fileId = existingFiles.files!.first.id!;
        await _driveApi!.files.update(
          fileMetadata,
          fileId,
          uploadMedia: media,
        );
      } else {
        // Create new file
        await _driveApi!.files.create(
          fileMetadata,
          uploadMedia: media,
        );
      }

      return true;
    } catch (e) {
      print('Error uploading file $fileName: $e');
      return false;
    }
  }

  // Download a file from Google Drive
  Future<String?> _downloadFile(String fileName, String? folderId) async {
    if (_driveApi == null) return null;

    try {
      String query = "name='$fileName' and trashed=false";
      if (folderId != null) {
        query += " and '$folderId' in parents";
      }

      final fileList = await _driveApi!.files.list(q: query, spaces: 'drive');

      if (fileList.files == null || fileList.files!.isEmpty) {
        return null;
      }

      final fileId = fileList.files!.first.id!;
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (var data in media.stream) {
        dataStore.addAll(data);
      }

      return utf8.decode(dataStore);
    } catch (e) {
      print('Error downloading file $fileName: $e');
      return null;
    }
  }

  // Backup all data to Google Drive
  Future<bool> backupToCloud(String userId) async {
    if (!isSignedIn || _driveApi == null) {
      print('Not signed in to Google');
      return false;
    }

    try {
      final folderId = await _getAppFolderId();
      if (folderId == null) {
        print('Could not get/create app folder');
        return false;
      }

      // Get local files
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');

      final files = [
        'transactions_$userId.json',
        'budgets_$userId.json',
        'products_$userId.json',
        'wallets_$userId.json',
        'rules_$userId.json',
      ];

      bool allSuccess = true;

      for (final fileName in files) {
        final file = File('${cacheDir.path}/$fileName');
        if (await file.exists()) {
          final content = await file.readAsString();
          final success = await _uploadFile(fileName, content, folderId);
          if (!success) {
            allSuccess = false;
            print('Failed to upload $fileName');
          }
        }
      }

      // Save metadata
      final metadata = {
        'lastBackup': DateTime.now().toIso8601String(),
        'userId': userId,
        'version': '2.0.0',
      };
      await _uploadFile('metadata.json', jsonEncode(metadata), folderId);

      return allSuccess;
    } catch (e) {
      print('Error during backup: $e');
      return false;
    }
  }

  // Restore data from Google Drive
  Future<bool> restoreFromCloud(String userId) async {
    if (!isSignedIn || _driveApi == null) {
      print('Not signed in to Google');
      return false;
    }

    try {
      final folderId = await _getAppFolderId();
      if (folderId == null) {
        print('No backup folder found');
        return false;
      }

      // Download all files
      final files = [
        'transactions_$userId.json',
        'budgets_$userId.json',
        'products_$userId.json',
        'wallets_$userId.json',
        'rules_$userId.json',
      ];

      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      bool anyRestored = false;

      for (final fileName in files) {
        final content = await _downloadFile(fileName, folderId);
        if (content != null) {
          final file = File('${cacheDir.path}/$fileName');
          await file.writeAsString(content);
          anyRestored = true;
          print('Restored $fileName');
        }
      }

      return anyRestored;
    } catch (e) {
      print('Error during restore: $e');
      return false;
    }
  }

  // Get last backup time
  Future<DateTime?> getLastBackupTime() async {
    if (!isSignedIn || _driveApi == null) return null;

    try {
      final folderId = await _getAppFolderId();
      if (folderId == null) return null;

      final content = await _downloadFile('metadata.json', folderId);
      if (content != null) {
        final metadata = jsonDecode(content);
        return DateTime.parse(metadata['lastBackup']);
      }
    } catch (e) {
      print('Error getting last backup time: $e');
    }

    return null;
  }

  // Delete all cloud backup data
  Future<bool> deleteCloudBackup() async {
    if (!isSignedIn || _driveApi == null) return false;

    try {
      final folderId = await _getAppFolderId();
      if (folderId == null) return false;

      await _driveApi!.files.delete(folderId);
      return true;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

/// Service to initialize and manage Firebase
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Sign in anonymously (for testing)
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await auth.signInAnonymously();
      print('✅ Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('❌ Error signing in anonymously: $e');
      return null;
    }
  }

  /// Sign in with custom token (for API key-based auth)
  Future<User?> signInWithCustomToken(String token) async {
    try {
      final userCredential = await auth.signInWithCustomToken(token);
      print('✅ Signed in with custom token: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('❌ Error signing in with custom token: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  /// Get current user
  User? get currentUser => auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Test Firestore connection
  Future<bool> testConnection() async {
    try {
      // Try to read from Firestore
      await firestore
          .collection('test')
          .doc('connection')
          .get()
          .timeout(const Duration(seconds: 5));
      print('✅ Firestore connection successful');
      return true;
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/widgets.dart';

/// Service quản lý trạng thái online/offline của user
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  bool _isOnline = false;
  bool _isInitialized = false;

  /// Khởi tạo presence service
  /// Gọi khi user đăng nhập
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ PresenceService: No user logged in');
      return;
    }

    try {
      // Set online status
      await _setOnline(true);
      _isOnline = true;
      _isInitialized = true;

      // Listen to app lifecycle để tự động update khi app vào background
      // Sẽ được gọi từ main.dart hoặc app lifecycle observer
      
      print('✅ PresenceService: Initialized for user ${user.uid}');
    } catch (e) {
      print('❌ PresenceService: Error initializing: $e');
    }
  }

  /// Set trạng thái online/offline
  Future<void> _setOnline(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      _isOnline = isOnline;
      print('✅ PresenceService: Set online = $isOnline');
    } catch (e) {
      print('❌ PresenceService: Error setting online status: $e');
    }
  }

  /// Set online khi app vào foreground
  Future<void> setOnline() async {
    if (!_isOnline) {
      await _setOnline(true);
    }
  }

  /// Set offline khi app vào background hoặc đóng
  Future<void> setOffline() async {
    if (_isOnline) {
      await _setOnline(false);
    }
  }

  /// Cleanup khi user đăng xuất
  Future<void> cleanup() async {
    await setOffline();
    _isInitialized = false;
    print('✅ PresenceService: Cleaned up');
  }
}


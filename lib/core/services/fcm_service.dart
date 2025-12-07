import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'notification_navigation_service.dart';

/// Service quản lý Firebase Cloud Messaging (FCM)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  String? _currentToken;
  bool _initialized = false;

  /// Khởi tạo FCM service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Yêu cầu quyền notification (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM: User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ FCM: User granted provisional permission');
      } else {
        print('❌ FCM: User declined or has not accepted permission');
        return;
      }

      // Lấy token ban đầu
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        print('✅ FCM: Initial token: ${_currentToken!.substring(0, 20)}...');
        await _saveTokenToFirestore(_currentToken!);
      }

      // Lắng nghe token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM: Token refreshed: ${newToken.substring(0, 20)}...');
        _currentToken = newToken;
        _saveTokenToFirestore(newToken);
      });

      // Xử lý notification khi app ở foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Xử lý khi user tap notification (app đang background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Xử lý khi user tap notification (app terminated)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _initialized = true;
      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ FCM: Error initializing: $e');
    }
  }

  /// Lưu FCM token vào Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ FCM: No user logged in, skipping token save');
      return;
    }

    try {
      // Lưu token vào users/{userId}/fcmTokens/{tokenId}
      // Sử dụng token làm document ID để tránh duplicate
      final tokenId = token.substring(0, 20); // Dùng 20 ký tự đầu làm ID
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(tokenId)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ FCM: Token saved to Firestore');
    } catch (e) {
      print('❌ FCM: Error saving token: $e');
    }
  }

  /// Xử lý notification khi app ở foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 FCM: Foreground message received');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // TODO: Hiển thị in-app notification (SnackBar, Dialog, hoặc custom banner)
    // Hiện tại chỉ log, sẽ implement UI sau
  }

  /// Xử lý khi user tap notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('👆 FCM: Notification tapped');
    print('   Data: ${message.data}');

    // Gửi event đến NotificationNavigationService để xử lý navigation
    NotificationNavigationService().handleNotificationTap(message.data);
  }

  /// Xóa token khi user đăng xuất
  Future<void> deleteToken() async {
    final user = _auth.currentUser;
    if (user == null || _currentToken == null) return;

    try {
      final tokenId = _currentToken!.substring(0, 20);
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(tokenId)
          .delete();

      await _messaging.deleteToken();
      _currentToken = null;
      print('✅ FCM: Token deleted');
    } catch (e) {
      print('❌ FCM: Error deleting token: $e');
    }
  }

  /// Lấy token hiện tại
  String? get currentToken => _currentToken;
}

/// Top-level function để xử lý background message
/// Phải là top-level function, không thể là method của class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Khởi tạo Firebase nếu chưa có (cần cho background handler)
  await Firebase.initializeApp();
  print('📨 FCM: Background message received');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');

  // TODO: Có thể tạo notification trong Firestore để sync khi app mở lại
  // Hoặc chỉ log, vì notification đã được hiển thị bởi system
}


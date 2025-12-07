import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart' show hasSeenOnboarding, OnboardingScreen;
import 'features/onboarding/splash_screen.dart' show SplashScreen;
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/email_verification_screen.dart';
import 'core/cache/hive_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/presence_service.dart';
import 'core/services/notification_navigation_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://ggzbqntuahhnxwpemztt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdnemJxbnR1YWhobnh3cGVtenR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMjEyMzcsImV4cCI6MjA3OTg5NzIzN30.MZFX0BNk97MFEGyZLbaVAzgo4rcpW0OaQGy2khAimrU',
  );
  
  // Khởi tạo Hive cache
  await HiveService.init();
  
  // Đăng ký background message handler (phải gọi trước runApp)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Khởi tạo FCM service
  await FCMService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set navigator key cho NotificationNavigationService
    // Note: NotificationNavigationService sẽ dùng context từ navigator
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Quản lý presence khi app vào background/foreground
    switch (state) {
      case AppLifecycleState.resumed:
        PresenceService().setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        PresenceService().setOffline();
        break;
      case AppLifecycleState.hidden:
        // iOS specific
        PresenceService().setOffline();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return MaterialApp(
      title: 'Nhà Trọ 360',
      debugShowCheckedModeBanner: false,
      theme: theme,
      navigatorKey: _navigatorKey,
      home: const _RootDecider(),
    );
  }
}

/// Quyết định flow: Splash -> Onboarding (nếu chưa xem) -> Auth check -> Home/Login.
class _RootDecider extends StatefulWidget {
  const _RootDecider();

  @override
  State<_RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<_RootDecider> {
  bool _showSplash = true;
  bool _hasSeenOnboarding = false;
  firebase_auth.User? _user;

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
    _listenAuthState();
  }

  void _listenAuthState() {
    // Listen auth state changes
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebase_auth.User? user) async {
      if (mounted) {
        setState(() {
          _user = user;
        });
        
        // Khởi tạo presence service khi user đăng nhập
        if (user != null) {
          await PresenceService().initialize();
          
          // Tự động lưu user info vào users collection nếu chưa có
          await _ensureUserDocument(user);
        }
      }
    });
  }

  Future<void> _loadOnboardingFlag() async {
    final seen = await hasSeenOnboarding();
    if (!mounted) return;
    setState(() {
      _hasSeenOnboarding = seen;
    });
  }

  /// Đảm bảo user document tồn tại trong users collection với thông tin đầy đủ.
  Future<void> _ensureUserDocument(firebase_auth.User user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      // Nếu chưa có document hoặc thiếu thông tin, cập nhật
      if (!userDoc.exists || 
          userDoc.data()?['displayName'] == null ||
          userDoc.data()?['email'] == null) {
        final updateData = <String, dynamic>{
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Thêm displayName nếu có
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          updateData['displayName'] = user.displayName;
        } else if (user.email != null) {
          // Nếu không có displayName, dùng phần trước @ của email
          updateData['displayName'] = user.email!.split('@')[0];
        }
        
        // Thêm photoURL nếu có
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          updateData['photoURL'] = user.photoURL;
        }
        
        // Thêm phoneNumber nếu có
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          updateData['phone'] = user.phoneNumber;
        }
        
        // Nếu chưa có document, thêm createdAt
        if (!userDoc.exists) {
          updateData['createdAt'] = FieldValue.serverTimestamp();
        }
        
        await firestore.collection('users').doc(user.uid).set(
          updateData,
          SetOptions(merge: true),
        );
        
        print('✅ Đã cập nhật user document cho ${user.uid}');
      }
    } catch (e) {
      print('⚠️ Lỗi khi đảm bảo user document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      // Hiển thị splash trong 2–3 giây, sau đó chuyển sang
      // Onboarding hoặc Auth check nhưng không thay route.
      return SplashScreen(
        onFinished: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        onFinished: () {
          setState(() {
            _hasSeenOnboarding = true;
          });
        },
      );
    }

    // Kiểm tra auth state
    if (_user == null) {
      // Chưa đăng nhập → Login
      return const LoginScreen();
    }

    // Đã đăng nhập nhưng chưa verify email → Email Verification
    if (!_user!.emailVerified) {
      return EmailVerificationScreen(email: _user!.email!);
    }

    // Đã đăng nhập và đã verify → Home
    // Xử lý pending notification nếu có (sau khi widget được build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lấy context từ MaterialApp navigator
      final navigator = Navigator.of(context);
      if (navigator.context.mounted) {
        NotificationNavigationService().handlePendingNotification(navigator.context);
      }
    });
    
    return const HomeShell();
  }
}

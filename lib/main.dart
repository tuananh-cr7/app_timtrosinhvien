import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart' show hasSeenOnboarding, OnboardingScreen;
import 'features/onboarding/splash_screen.dart' show SplashScreen;
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/email_verification_screen.dart';
import 'core/cache/hive_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/presence_service.dart';
import 'core/services/notification_navigation_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/offline_queue_service.dart';
import 'core/services/service_locator.dart';
import 'core/widgets/offline_indicator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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
  late final ConnectivityService _connectivityService;
  late final OfflineQueueService _offlineQueueService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Khởi tạo connectivity và offline queue services
    _connectivityService = ConnectivityService();
    _offlineQueueService = OfflineQueueService(_connectivityService);
    
    // Đăng ký services vào service locator
    ServiceLocator.register(
      connectivityService: _connectivityService,
      offlineQueueService: _offlineQueueService,
    );
    
    // Lắng nghe connectivity changes để sync queue khi online
    _connectivityService.addListener(_onConnectivityChanged);
    
    // Set navigator key cho NotificationNavigationService
    // Note: NotificationNavigationService sẽ dùng context từ navigator
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline) {
      // Sync queue khi online
      _offlineQueueService.syncQueue();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.removeListener(_onConnectivityChanged);
    _connectivityService.dispose();
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
      home: _RootDecider(
        connectivityService: _connectivityService,
        offlineQueueService: _offlineQueueService,
      ),
    );
  }
}

/// Quyết định flow: Splash -> Onboarding (nếu chưa xem) -> Auth check -> Home/Login.
class _RootDecider extends StatefulWidget {
  const _RootDecider({
    required this.connectivityService,
    required this.offlineQueueService,
  });

  final ConnectivityService connectivityService;
  final OfflineQueueService offlineQueueService;

  @override
  State<_RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<_RootDecider> {
  bool _showSplash = true;
  bool _hasSeenOnboarding = false;
  firebase_auth.User? _user;
  bool _isCheckingBan = false;
  bool _isBanned = false;
  String? _banReason;
  bool _isAdminBlocked = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
    _listenAuthState();
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }

  void _listenAuthState() {
    // Listen auth state changes
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebase_auth.User? user) async {
      if (mounted) {
        setState(() {
          _user = user;
          _isBanned = false;
          _banReason = null;
          _isAdminBlocked = false;
        });

        // Hủy listener user cũ nếu có
        _userDocSub?.cancel();
        _userDocSub = null;

        // Khởi tạo presence service khi user đăng nhập
        if (user != null) {
          await PresenceService().initialize();
          
          // Tự động lưu user info vào users collection nếu chưa có
          await _ensureUserDocument(user);

          // Nếu là admin claim, chặn đăng nhập app người dùng
          final blocked = await _checkAdminClaim(user);
          if (blocked) {
            await firebase_auth.FirebaseAuth.instance.signOut();
            return;
          }

          // Lắng nghe realtime trạng thái khóa tài khoản
          _userDocSub = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots()
              .listen((doc) {
            final data = doc.data();
            final banned = data?['banned'] == true;
            final reason = data?['banReason'] as String?;
            if (!mounted) return;
            setState(() {
              _isBanned = banned;
              _banReason = banned ? reason : null;
            });
            debugPrint('🔒 Realtime ban change -> banned=$banned reason=${reason ?? "none"}');
          });

          // Kiểm tra trạng thái khóa tài khoản lần đầu từ server để tránh cache cũ
          final bannedNow = await _checkBan(user);
          if (bannedNow) {
            debugPrint('🔒 Banned detected on login, keeping user on banned screen.');
          }
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

  /// Kiểm tra xem user có bị khóa không. Nếu bị khóa, sẽ hiển thị thông báo và không cho vào app.
  Future<bool> _checkBan(firebase_auth.User user) async {
    setState(() {
      _isCheckingBan = true;
      _isBanned = false;
      _banReason = null;
    });
    bool banned = false;
    String? reason;
    try {
      // Luôn lấy từ server để không dính cache cũ
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final data = doc.data();
      banned = data?['banned'] == true;
      reason = data?['banReason'] as String?;
      if (banned) {
        setState(() {
          _isBanned = true;
          _banReason = reason;
        });
        debugPrint('🔒 Ban check (server) -> banned=$banned reason=${reason ?? "none"}');
      } else {
        debugPrint('✅ Ban check (server) -> not banned');
      }
    } catch (e) {
      // Nếu lỗi, không chặn nhưng log ra
      debugPrint('⚠️ Lỗi kiểm tra khóa tài khoản: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingBan = false;
        });
      }
    }
    return banned;
  }

  /// Chặn tài khoản có claim admin/role admin đăng nhập app người dùng.
  Future<bool> _checkAdminClaim(firebase_auth.User user) async {
    try {
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? {};
      final isAdmin =
          claims['admin'] == true || claims['role'] == 'admin' || claims['role'] == 'super_admin';
      if (isAdmin) {
        if (mounted) {
          setState(() => _isAdminBlocked = true);
        }
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi kiểm tra admin claim: $e');
    }
    return false;
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

    // Nếu phát hiện claim admin, chặn đăng nhập app người dùng
    if (_isAdminBlocked) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, color: Colors.orange, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Tài khoản này là admin, không thể đăng nhập ứng dụng người dùng.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hãy dùng trang Admin (main_admin.dart) để truy cập chức năng quản trị.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (mounted) {
                      setState(() => _isAdminBlocked = false);
                    }
                  },
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Kiểm tra auth state
    if (_user == null) {
      // Chưa đăng nhập → Login
      return const LoginScreen();
    }

    // Đang kiểm tra trạng thái khóa
    if (_isCheckingBan) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Bị khóa tài khoản
    if (_isBanned) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Tài khoản của bạn đã bị khóa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _banReason ?? 'Vui lòng liên hệ quản trị viên để biết thêm chi tiết.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      );
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
    
    return HomeShell(
      connectivityService: widget.connectivityService,
      offlineQueueService: widget.offlineQueueService,
    );
  }
}

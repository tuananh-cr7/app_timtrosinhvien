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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebase_auth.User? user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
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
    return const HomeShell();
  }
}

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/presence_service.dart';

/// Service quản lý xác thực Firebase Auth.
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream user hiện tại (dùng để listen auth state changes).
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại (null nếu chưa đăng nhập).
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Đăng ký với email/password.
  /// Trả về User nếu thành công, throw exception nếu lỗi.
  Future<firebase_auth.User> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật displayName nếu có
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      // Gửi email verification tự động
      await credential.user?.sendEmailVerification();

      return credential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Đăng nhập với email/password.
  Future<firebase_auth.User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Đăng nhập với Google.
  Future<firebase_auth.User> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User đã hủy flow
        throw Exception('Đăng nhập Google bị hủy');
      }

      // Lấy authentication details từ request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Tạo credential từ Google
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase
      final userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Xử lý lỗi hủy hoặc lỗi khác
      rethrow;
    }
  }

  /// Gửi email reset password.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Gửi lại email verification.
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }
    if (user.emailVerified) {
      throw Exception('Email đã được xác thực');
    }
    try {
      await user.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Kiểm tra email đã được verify chưa (reload user trước).
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Đăng xuất.
  Future<void> signOut() async {
    // Xóa FCM token trước khi đăng xuất
    try {
      await FCMService().deleteToken();
    } catch (e) {
      print('⚠️ AuthService: Error deleting FCM token: $e');
    }
    
    // Set offline status
    try {
      await PresenceService().cleanup();
    } catch (e) {
      print('⚠️ AuthService: Error cleaning up presence: $e');
    }
    // Đăng xuất Firebase Auth (quan trọng nhất)
    await _auth.signOut();
    
    // Đăng xuất Google Sign-In (nếu có) - bỏ qua lỗi nếu không cần thiết
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Bỏ qua lỗi Google Sign-In nếu user không đăng nhập bằng Google
      // hoặc Google Sign-In chưa được khởi tạo
    }
  }

  /// Đổi mật khẩu (cần re-authenticate trước).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }
    if (user.email == null) {
      throw Exception('Không có email để đổi mật khẩu');
    }

    try {
      // Bước 1: Re-authenticate với mật khẩu hiện tại
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Bước 2: Đổi mật khẩu mới
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Xóa tài khoản.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }
    try {
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Chuyển đổi FirebaseAuthException sang message tiếng Việt.
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-credential': // Firebase Auth SDK mới
      case 'invalid-login-credentials': // Một số phiên bản SDK trả về code này
        return 'Email hoặc mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập không được phép';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để thực hiện thao tác này';
      default:
        return e.message ?? 'Đã xảy ra lỗi: ${e.code}';
    }
  }
}


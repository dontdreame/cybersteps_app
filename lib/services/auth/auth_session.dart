import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/student.dart';

import 'token_storage.dart';
import 'auth_api.dart';
import 'firebase_bootstrap.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthSession extends ChangeNotifier {
  AuthSession({
    required TokenStorage tokenStorage,
    required AuthApi api,
  })  : _tokenStorage = tokenStorage,
        _api = api;

  static const String _mockPrefix = 'mock:';

  final TokenStorage _tokenStorage;
  final AuthApi _api;

  AuthStatus status = AuthStatus.unknown;
  bool isBusy = false;
  bool isMeLoading = false;
  String? meError;

  String? token;
  Student? me;

  bool get isAuthed => status == AuthStatus.authenticated;

  Student _defaultMockMe() => Student(
        id: 'mock-student',
        fullName: 'Mock Student',
        email: 'mock@cybersteps.local',
        levelId: 0,
        totalPoints: 0,
      );

  /// Bootstrap on app start:
  /// - If no token => unauthenticated
  /// - If mock token => authenticated (no backend call)
  /// - Otherwise validate with /students/me
  Future<void> bootstrap() async {
    if (status != AuthStatus.unknown) return;

    isBusy = true;
    notifyListeners();

    try {
      meError = null;
      // ensure Firebase is initialized (safe to call multiple times)
      await FirebaseBootstrap.ensureInitialized();

      token = await _tokenStorage.readToken();
      if (token == null || token!.isEmpty) {
        status = AuthStatus.unauthenticated;
        return;
      }

      if (token!.startsWith(_mockPrefix)) {
        me = _defaultMockMe();
        status = AuthStatus.authenticated;
        return;
      }

      // validate token with /students/me
      me = await _api.fetchMeStudent(token: token);
      meError = null;
      status = AuthStatus.authenticated;
    } catch (_) {
      await _tokenStorage.clearToken();
      token = null;
      me = null;
      status = AuthStatus.unauthenticated;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// ===== Firebase → Backend JWT =====
  Future<void> loginWithFirebaseIdToken(String idToken) async {
    isBusy = true;
    notifyListeners();
    try {
      meError = null;
      final jwt = await _api.loginWithFirebaseIdToken(idToken);
      await _tokenStorage.saveToken(jwt);

      token = jwt;

      // IMPORTANT: pass token explicitly to avoid first-call Authorization race
      me = await _api.fetchMeStudent(token: jwt);
      meError = null;
      status = AuthStatus.authenticated;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Email/password via Firebase Auth then exchange idToken -> JWT
  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    isBusy = true;
    notifyListeners();
    try {
      meError = null;
      await FirebaseBootstrap.ensureInitialized();

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final idToken = await cred.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to get Firebase idToken');
      }

      await loginWithFirebaseIdToken(idToken);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// ===== Phone OTP via Firebase Auth =====
  String? _verificationId;

  Future<void> startPhoneLogin(String phone) async {
    isBusy = true;
    notifyListeners();
    try {
      meError = null;
      await FirebaseBootstrap.ensureInitialized();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolved — sign in immediately
          final cred = await FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await cred.user?.getIdToken();
          if (idToken == null || idToken.isEmpty) return;
          await loginWithFirebaseIdToken(idToken);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (_verificationId == null || _verificationId!.isEmpty) {
      throw Exception('Missing verificationId. Start phone login first.');
    }

    isBusy = true;
    notifyListeners();
    try {
      meError = null;
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp.trim(),
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);

      final idToken = await cred.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to get Firebase idToken');
      }

      await loginWithFirebaseIdToken(idToken);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// ===== Mock login (offline dev) =====
  Future<void> mockLogin({Map<String, dynamic>? mockMe}) async {
    isBusy = true;
    notifyListeners();
    try {
      meError = null;
      final jwt = '$_mockPrefix${DateTime.now().millisecondsSinceEpoch}';
      await _tokenStorage.saveToken(jwt);
      token = jwt;
      // `mockMe` can be a raw API response map. Convert it to Student.
      me = mockMe != null ? Student.fromApiResponse(mockMe) : _defaultMockMe();
      status = AuthStatus.authenticated;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }


  Future<void> refreshMe() async {
    if (!isAuthed) return;
    final t = token;
    if (t == null || t.trim().isEmpty) return;

    isMeLoading = true;
    meError = null;
    notifyListeners();

    try {
      meError = null;
      if (t.startsWith(_mockPrefix)) {
        me = _defaultMockMe();
        return;
      }
      me = await _api.fetchMeStudent(token: t);
      meError = null;
    } catch (e) {
      meError = e.toString();
    } finally {
      isMeLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    token = null;
    me = null;
    status = AuthStatus.unauthenticated;

    // optional: sign out firebase session
    try {
      meError = null;
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    notifyListeners();
  }
}

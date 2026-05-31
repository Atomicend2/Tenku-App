import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, emailUnverified, profileSetup }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        notifyListeners();
      } else {
        if (!user.emailVerified) {
          _status = AuthStatus.emailUnverified;
          notifyListeners();
          return;
        }

        final userProfile = await _authService.getUserProfile(user.uid);
        if (userProfile == null) {
          _status = AuthStatus.profileSetup;
          notifyListeners();
          return;
        }

        _currentUser = userProfile;
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );

      if (user != null) {
        _status = AuthStatus.emailUnverified;
        notifyListeners();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> checkEmailVerification() async {
    final verified = await _authService.checkEmailVerification();
    if (verified) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
    return verified;
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    _setLoading(true);

    try {
      await _authService.updateProfile(
        uid: _currentUser!.uid,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  void refreshUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error.replaceAll('Exception: ', '');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}

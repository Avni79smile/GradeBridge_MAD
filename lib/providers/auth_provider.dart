import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Biometric
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  // PIN
  String? _userPin;
  bool _isPinEnabled = false;

  // Remember Me (credentials stored locally for biometric/PIN re-auth)
  bool _rememberMe = false;
  String? _rememberedEmail;
  String? _rememberedPassword;
  String? _rememberedRole;

  // Persistent session credentials — always saved on every login, cleared only
  // on explicit logout. Enables silent re-login for ALL users regardless of the
  // "Remember Me" checkbox, surviving app restarts and token expiry.
  bool _isExplicitLogout = false;
  String? _sessionEmail;
  String? _sessionPassword;
  String? _sessionRole;

  // Secure storage for sensitive data (not available on web)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Auth state stream subscription (for persistent session)
  StreamSubscription<AuthState>? _authStateSubscription;

  // Guard against concurrent/double initialisation
  Completer<void>? _initCompleter;

  SupabaseClient get _supabase => Supabase.instance.client;

  // ============ GETTERS ============

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isPinEnabled => _isPinEnabled;
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;
  String? get rememberedPassword => _rememberedPassword;
  String? get rememberedRole => _rememberedRole;

  // ============ SECURE STORAGE HELPERS ============

  Future<String?> _secureRead(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('secure_$key');
    }
    return await _secureStorage.read(key: key);
  }

  Future<void> _secureWrite(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secure_$key', value);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> _secureDelete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('secure_$key');
      return;
    }
    await _secureStorage.delete(key: key);
  }

  // ============ SESSION CREDENTIAL PERSISTENCE ============

  Future<void> _loadSessionCredentials() async {
    try {
      _sessionEmail = await _secureRead('session_email');
      _sessionPassword = await _secureRead('session_password');
      _sessionRole = await _secureRead('session_role');
    } catch (e) {
      debugPrint('Failed to load session credentials: $e');
    }
  }

  Future<void> _saveSessionCredentials(
    String email,
    String password,
    String role,
  ) async {
    try {
      await _secureWrite('session_email', email);
      await _secureWrite('session_password', password);
      await _secureWrite('session_role', role);
      _sessionEmail = email;
      _sessionPassword = password;
      _sessionRole = role;
    } catch (e) {
      debugPrint('Failed to save session credentials: $e');
    }
  }

  Future<void> _clearSessionCredentials() async {
    try {
      await _secureDelete('session_email');
      await _secureDelete('session_password');
      await _secureDelete('session_role');
    } catch (e) {
      debugPrint('Failed to clear session credentials: $e');
    }
    _sessionEmail = null;
    _sessionPassword = null;
    _sessionRole = null;
  }

  /// Silently re-authenticate using stored credentials.
  /// Prefers session credentials; falls back to Remember-Me credentials.
  /// Returns true if successful.
  Future<bool> _trySilentReLogin() async {
    // Use session credentials first, fall back to Remember Me credentials.
    final email = _sessionEmail ?? _rememberedEmail;
    final password = _sessionPassword ?? _rememberedPassword;
    if (email == null || password == null) return false;
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final foundRole =
            (response.user!.userMetadata?['role'] as String?)?.trim() ?? '';
        final responseRole = foundRole.isNotEmpty ? foundRole : 'student';

        final expectedRole = _sessionRole ?? _rememberedRole;
        debugPrint(
          'Silent login attempt: email=$email, expectedRole=$expectedRole, responseRole=$responseRole',
        );

        if (expectedRole != null && expectedRole != responseRole) {
          await _supabase.auth.signOut();
          debugPrint(
            'Silent login role mismatch: expected=$expectedRole, actual=$responseRole',
          );
          return false;
        }

        _currentUser = AppUser.fromSupabaseUser(response.user!);
        debugPrint('Silent login success for $email (role $responseRole)');
        return true;
      }
    } catch (_) {
      // Network error or invalid credentials — silent failure.
    }
    return false;
  }

  // ============ INITIALISATION ============

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Prevent concurrent or duplicate initialisation calls.
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    _initCompleter = Completer<void>();

    // ── Step 1: Synchronous check ──────────────────────────────────────────
    // supabase_flutter loads the stored session into memory synchronously
    // during Supabase.initialize(). Check here BEFORE any async work so we
    // don't miss it even if the INITIAL_SESSION event fires before our
    // listener is attached.
    final syncUser = _supabase.auth.currentUser;
    if (syncUser != null) {
      _currentUser = AppUser.fromSupabaseUser(syncUser);
    }

    // ── Step 2: Load stored re-login credentials ───────────────────────────
    await _loadSessionCredentials();
    await _loadRememberMeSetting(); // needed early so _trySilentReLogin can use _rememberedEmail

    // ── Step 3: Subscribe to auth state changes ────────────────────────────
    final sessionCompleter = Completer<void>();

    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;

      if (session != null) {
        _currentUser = AppUser.fromSupabaseUser(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        if (_isExplicitLogout) {
          // Deliberate logout — clear current user and stop.
          _currentUser = null;
        } else {
          // Session expired/revoked automatically — silently re-login so the
          // user never sees the login page unless they explicitly logged out.
          final success = await _trySilentReLogin();
          if (!success) {
            _currentUser = null;
          }
        }
      }

      if (!sessionCompleter.isCompleted) {
        sessionCompleter.complete();
      }

      notifyListeners();
    });

    // ── Step 4: Wait for INITIAL_SESSION only if needed ────────────────────
    // If we already have a user from the sync check (Step 1), skip the wait.
    // Otherwise wait up to 5 s; on timeout fall back to the SDK in-memory cache.
    if (_currentUser == null) {
      try {
        await sessionCompleter.future.timeout(const Duration(seconds: 5));
      } catch (_) {
        final user = _supabase.auth.currentUser;
        if (user != null && _currentUser == null) {
          _currentUser = AppUser.fromSupabaseUser(user);
        }
      }
    }

    await _checkBiometricAvailability();
    await _loadBiometricSetting();
    await _loadPinSetting();
    // Note: _loadRememberMeSetting() was already called in Step 2.

    // ── Step 5: Silent re-login if session still missing ──────────────────
    // Covers: token expired, offline restart, first run after fresh install.
    // _trySilentReLogin() tries session credentials first then Remember-Me.
    if (_currentUser == null) {
      await _trySilentReLogin();
    }

    _isInitialized = true;
    notifyListeners();
    _initCompleter!.complete();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    await _init();
  }

  // ============ BIOMETRIC AUTHENTICATION ============

  bool get _isBiometricSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkBiometricAvailability() async {
    if (!_isBiometricSupported) {
      _isBiometricAvailable = false;
      return;
    }
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _isBiometricAvailable = canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      _isBiometricAvailable = false;
      if (e is! MissingPluginException) {
        debugPrint('Error checking biometric availability: $e');
      }
    }
  }

  Future<void> _loadBiometricSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      debugPrint('Error loading biometric setting: $e');
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', enabled);
      _isBiometricEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving biometric setting: $e');
    }
  }

  Future<BiometricResult> authenticateWithBiometric() async {
    if (!_isBiometricAvailable) {
      return BiometricResult(
        success: false,
        message: 'Biometric authentication not available on this device',
      );
    }
    if (!_isBiometricEnabled) {
      return BiometricResult(
        success: false,
        message: 'Biometric login is not enabled',
      );
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to login to GradeBridge',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        if (_rememberedEmail != null &&
            _rememberedPassword != null &&
            _rememberedRole != null) {
          final result = await login(
            email: _rememberedEmail!,
            password: _rememberedPassword!,
            role: _rememberedRole!,
          );
          return BiometricResult(
            success: result.success,
            message: result.message,
            user: result.user,
          );
        }
        return BiometricResult(
          success: false,
          message: 'No saved credentials found. Please login with email first.',
        );
      }

      return BiometricResult(
        success: false,
        message: 'Biometric authentication failed',
      );
    } on PlatformException catch (e) {
      return BiometricResult(
        success: false,
        message: 'Biometric error: ${e.message}',
      );
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // ============ PIN AUTHENTICATION ============

  Future<void> _loadPinSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPinEnabled = prefs.getBool('pin_enabled') ?? false;
      if (_isPinEnabled) {
        _userPin = await _secureRead('user_pin');
      }
    } catch (e) {
      debugPrint('Error loading PIN setting: $e');
    }
  }

  Future<bool> setPin(String pin) async {
    try {
      await _secureWrite('user_pin', pin);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pin_enabled', true);
      _userPin = pin;
      _isPinEnabled = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving PIN: $e');
      return false;
    }
  }

  Future<bool> removePin() async {
    try {
      await _secureDelete('user_pin');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pin_enabled', false);
      _userPin = null;
      _isPinEnabled = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing PIN: $e');
      return false;
    }
  }

  Future<PinResult> authenticateWithPin(String enteredPin) async {
    if (!_isPinEnabled || _userPin == null) {
      return PinResult(success: false, message: 'PIN login is not enabled');
    }
    if (enteredPin != _userPin) {
      return PinResult(success: false, message: 'Incorrect PIN');
    }

    if (_rememberedEmail != null &&
        _rememberedPassword != null &&
        _rememberedRole != null) {
      final result = await login(
        email: _rememberedEmail!,
        password: _rememberedPassword!,
        role: _rememberedRole!,
      );
      return PinResult(
        success: result.success,
        message: result.message,
        user: result.user,
      );
    }

    return PinResult(
      success: false,
      message: 'No saved credentials found. Please login with email first.',
    );
  }

  // ============ REMEMBER ME ============

  Future<void> _loadRememberMeSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _rememberedEmail = await _secureRead('remembered_email');
        _rememberedPassword = await _secureRead('remembered_password');
        _rememberedRole = await _secureRead('remembered_role');
      }
    } catch (e) {
      debugPrint('Error loading remember me setting: $e');
    }
  }

  Future<void> setRememberMe(
    bool enabled, {
    String? email,
    String? password,
    String? role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', enabled);
      _rememberMe = enabled;

      if (enabled && email != null && password != null && role != null) {
        await _secureWrite('remembered_email', email);
        await _secureWrite('remembered_password', password);
        await _secureWrite('remembered_role', role);
        _rememberedEmail = email;
        _rememberedPassword = password;
        _rememberedRole = role;
      } else if (!enabled) {
        await _secureDelete('remembered_email');
        await _secureDelete('remembered_password');
        await _secureDelete('remembered_role');
        _rememberedEmail = null;
        _rememberedPassword = null;
        _rememberedRole = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving remember me setting: $e');
    }
  }

  Future<void> clearRememberedCredentials() async {
    await setRememberMe(false);
  }

  // ============ SUPABASE AUTH OPERATIONS ============

  /// Register a new user. Role ('student' or 'teacher') is stored in
  /// Supabase user_metadata so it persists across devices.
  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );

      _isLoading = false;

      if (response.user != null) {
        // If email confirmation is enabled, Supabase returns a user but no
        // active session until the user confirms via inbox link.
        if (response.session == null) {
          notifyListeners();
          return SignUpResult(
            success: true,
            message: 'Account created. Please confirm your email, then login.',
            user: null,
            requiresEmailConfirmation: true,
          );
        }

        _currentUser = AppUser.fromSupabaseUser(response.user!);

        // Persist credentials for silent re-login on app restart.
        await _saveSessionCredentials(email, password, role);

        notifyListeners();
        return SignUpResult(
          success: true,
          message: 'Account created successfully!',
          user: _currentUser,
        );
      }

      notifyListeners();
      return SignUpResult(
        success: false,
        message: 'Sign up failed. Please try again.',
      );
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return SignUpResult(success: false, message: e.message);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return SignUpResult(
        success: false,
        message: 'Sign up failed. Check your internet connection.',
      );
    }
  }

  /// Sign in with email and password.
  /// Also verifies the account [role] matches what is stored in Supabase metadata.
  Future<LoginResult> login({
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (response.user != null) {
        final foundRole =
            (response.user!.userMetadata?['role'] as String?)?.trim() ?? '';
        final storedRole = foundRole.isNotEmpty ? foundRole : 'student';

        debugPrint('Login role check: requested=$role, found=$storedRole');

        if (storedRole != role) {
          // Role mismatch — sign out immediately
          await _supabase.auth.signOut();
          debugPrint(
            'Login failed: expected role=$role, real role=$storedRole',
          );
          notifyListeners();
          return LoginResult(
            success: false,
            message: 'No $role account found with these credentials.',
          );
        }

        _currentUser = AppUser.fromSupabaseUser(response.user!);
        // Always persist credentials so silent re-login works for every user,
        // regardless of the "Remember Me" checkbox setting.
        await _saveSessionCredentials(email, password, role);
        notifyListeners();
        return LoginResult(
          success: true,
          message: 'Login successful!',
          user: _currentUser,
        );
      }

      notifyListeners();
      return LoginResult(success: false, message: 'Login failed.');
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed') ||
          msg.contains('email_not_confirmed')) {
        return LoginResult(
          success: false,
          message:
              'Please confirm your email address first. Check your inbox for a confirmation link.',
        );
      }
      return LoginResult(success: false, message: 'Invalid email or password.');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return LoginResult(
        success: false,
        message: 'Login failed. Check your internet connection.',
      );
    }
  }

  /// Sign out the current user.
  Future<void> logout() async {
    debugPrint('Logout called');
    // Mark explicit logout BEFORE signing out so the auth listener knows
    // not to silently re-login when it receives the signedOut event.
    _isExplicitLogout = true;
    // Erase all persistent credentials so an app restart lands on the login page.
    await _clearSessionCredentials();
    await setRememberMe(false);
    await _supabase.auth.signOut();
    _currentUser = null;
    _isExplicitLogout = false;
    notifyListeners();
    debugPrint('Logout complete');
  }

  /// Send a password-reset email. The user clicks the link to set a new password.
  Future<ResetPasswordResult> resetPassword({
    required String email,
    String? role, // kept for API compatibility; Supabase handles it by email
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return ResetPasswordResult(
        success: true,
        message:
            'Password reset email sent! Check your inbox and follow the link.',
      );
    } on AuthException catch (e) {
      return ResetPasswordResult(success: false, message: e.message);
    } catch (e) {
      return ResetPasswordResult(
        success: false,
        message: 'Failed to send reset email. Check your internet connection.',
      );
    }
  }

  /// Update the display name of the currently signed-in user.
  Future<void> updateUserProfile({String? name, String? email}) async {
    if (_currentUser == null) return;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;

      if (updates.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(data: updates));
      }

      // Reload user from Supabase
      final updated = _supabase.auth.currentUser;
      if (updated != null) {
        _currentUser = AppUser.fromSupabaseUser(updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  /// Check if an email is registered for the given role.
  /// NOTE: With Supabase we can't query other users client-side.
  /// We attempt a password-reset; if no account exists Supabase still
  /// returns success (to prevent email enumeration). We return true
  /// optimistically and let the email confirm existence.
  bool emailExistsForRole(String email, String role) {
    // Cannot query other users from client SDK.
    // Kept for API compatibility — the forgot-password page now uses
    // resetPassword() directly so this is a no-op check.
    return true;
  }
}

// ============ RESULT CLASSES ============

class SignUpResult {
  final bool success;
  final String message;
  final AppUser? user;
  final bool requiresEmailConfirmation;

  SignUpResult({
    required this.success,
    required this.message,
    this.user,
    this.requiresEmailConfirmation = false,
  });
}

class LoginResult {
  final bool success;
  final String message;
  final AppUser? user;

  LoginResult({required this.success, required this.message, this.user});
}

class ResetPasswordResult {
  final bool success;
  final String message;

  ResetPasswordResult({required this.success, required this.message});
}

class BiometricResult {
  final bool success;
  final String message;
  final AppUser? user;

  BiometricResult({required this.success, required this.message, this.user});
}

class PinResult {
  final bool success;
  final String message;
  final AppUser? user;

  PinResult({required this.success, required this.message, this.user});
}

// lib/providers/auth_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import 'api_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiService, storage);
});

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  final bool isAuthenticated;
  final bool isFaculty;
  final UserProfile? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.isAuthenticated = false,
    this.isFaculty = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isAuthenticated,
    bool? isFaculty,
    UserProfile? user,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isFaculty: isFaculty ?? this.isFaculty,
      user: clearUser ? null : (user ?? this.user),
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SecureStorageService _storage;
  StreamSubscription<void>? _unauthorizedSubscription;
  static const String _pendingApprovalMessage =
      'Your account is pending admin approval. Please wait for approval before signing in.';

  AuthNotifier(this._apiService, this._storage) : super(AuthState()) {
    _initializeAuth();
    _listenForUnauthorized();
  }

  void _listenForUnauthorized() {
    _unauthorizedSubscription = _apiService.onUnauthorized.listen((_) {
      // Force logout when 401 is received
      _forceLogout();
    });
  }

  Future<void> _forceLogout() async {
    await _apiService.clearToken();
    await _storage.clearAll();
    state = AuthState(
      isInitialized: true,
      error: 'Session expired. Please login again.',
    );
  }

  @override
  void dispose() {
    _unauthorizedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        // Check if token is expired using JWT decoder
        if (_isTokenExpired(token)) {
          // Token expired, clear storage
          await _storage.clearAll();
          state = AuthState(isInitialized: true);
          return;
        }

        // Token is valid, set it in API service
        await _apiService.setToken(token);
        state = state.copyWith(
          isAuthenticated: true,
          isFaculty: _isFacultyToken(token),
          isInitialized: true,
          isLoading: false,
        );
        await _loadUserProfile();
      } else {
        state = AuthState(isInitialized: true);
      }
    } catch (e) {
      state = AuthState(isInitialized: true, error: e.toString());
    }
  }

  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      // If token is malformed, consider it expired
      return true;
    }
  }

  bool _isFacultyToken(String token) {
    try {
      final decoded = JwtDecoder.decode(token);

      final roles = decoded['roles'];
      if (roles is List) {
        for (final role in roles) {
          if (role is String && role.toUpperCase() == 'ROLE_FACULTY') {
            return true;
          }
        }
      }

      final role = decoded['role'];
      if (role is int) {
        return role == 3;
      }
      if (role is String) {
        final normalized = role.toLowerCase();
        return normalized == 'faculty' ||
            normalized == 'role_faculty' ||
            normalized == '3';
      }
    } catch (_) {
      // Ignore decode errors and default to non-faculty.
    }

    return false;
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.login(identifier, password);

      if (_isAccountPendingApproval(response)) {
        state = state.copyWith(
          isLoading: false,
          error: _pendingApprovalMessage,
        );
        return;
      }

      final token = (response['token'] ??
          response['access_token'] ??
          response['accessToken']) as String?;

      if (token == null || token.isEmpty) {
        final serverMessage = _extractMessageFromResponse(response);
        state = state.copyWith(
          isLoading: false,
          error: _normalizeLoginError(
            serverMessage ?? 'Login failed: No token received from server',
          ),
        );
        return;
      }

      await _apiService.setToken(token);
      await _storage.saveToken(token);

      // Load profile before marking as authenticated for smoother UX
      UserProfile? userProfile;
      try {
        final profileResponse = await _apiService.getFacultyProfile();
        userProfile = UserProfile.fromJson(profileResponse);
        await _storage.saveUserData(jsonEncode(profileResponse));
      } catch (e) {
        // Profile load failed but login succeeded - continue with null user
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isFaculty: _isFacultyToken(token),
        user: userProfile,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _normalizeLoginError(e.toString()),
      );
    }
  }

  String _normalizeLoginError(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return 'Login failed. Please try again.';
    }

    if (_looksLikeApprovalPendingText(normalized)) {
      return _pendingApprovalMessage;
    }

    return normalized;
  }

  bool _isAccountPendingApproval(Map<String, dynamic> response) {
    final statuses = [
      response['status'],
      response['account_status'],
      response['approval_status'],
      response['user_status'],
    ];

    for (final status in statuses) {
      if (status is String && _looksLikeApprovalPendingText(status)) {
        return true;
      }
    }

    final approvedFlags = [
      response['approved'],
      response['is_approved'],
      response['isApproved'],
    ];
    if (approvedFlags.any((value) => value == false)) {
      return true;
    }

    final activeFlags = [
      response['active'],
      response['is_active'],
      response['isActive'],
    ];
    if (activeFlags.any((value) => value == false)) {
      return true;
    }

    final serverMessage = _extractMessageFromResponse(response);
    return serverMessage != null &&
        _looksLikeApprovalPendingText(serverMessage);
  }

  String? _extractMessageFromResponse(Map<String, dynamic> response) {
    final messageCandidates = [
      response['message'],
      response['detail'],
      response['reason'],
      response['error'],
    ];

    for (final candidate in messageCandidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }

      if (candidate is Map<String, dynamic>) {
        final nestedMessage = candidate['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }
    }

    return null;
  }

  bool _looksLikeApprovalPendingText(String text) {
    final lower = text.toLowerCase();

    if (lower == 'pending' || lower == 'inactive' || lower == 'disabled') {
      return true;
    }

    if (lower.contains('pending approval') ||
        lower.contains('approval pending') ||
        lower.contains('awaiting approval') ||
        lower.contains('pending admin') ||
        lower.contains('awaiting admin') ||
        lower.contains('not approved') ||
        lower.contains('unapproved') ||
        lower.contains('approval required') ||
        (lower.contains('approved') &&
            (lower.contains('not') || lower.contains('yet'))) ||
        lower.contains('inactive') ||
        lower.contains('not active')) {
      return true;
    }

    return false;
  }

  Future<String?> register({
    required String username,
    required String employeeId,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.register(
        username: username,
        employeeId: employeeId,
        email: email,
        password: password,
      );

      final message =
          (response['message'] as String?) ?? 'Registration successful.';
      state = state.copyWith(isLoading: false, error: null);
      return message;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _apiService.getFacultyProfile();
      final userData = UserProfile.fromJson(response);
      await _storage.saveUserData(jsonEncode(response));
      state = state.copyWith(user: userData);
    } catch (e) {
      // Don't set error for profile load failure if already authenticated
      // The user can still use the app
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateFacultyProfile(data);
      await _loadUserProfile();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore logout API errors - still clear local state
    } finally {
      await _apiService.clearToken();
      await _storage.clearAll();
      state = AuthState(isInitialized: true);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

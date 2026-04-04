// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'api_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiService, storage);
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserProfile? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserProfile? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final dynamic _apiService;
  final dynamic _storage;

  AuthNotifier(this._apiService, this._storage) : super(AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
      await _loadUserProfile();
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.login(username, password);
      final token = response['token'];

      if (token != null) {
        await _apiService.setToken(token);
        await _storage.saveToken(token);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
        );

        await _loadUserProfile();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _apiService.getFacultyProfile();
      final userData = UserProfile.fromJson(response);
      await _storage.saveUserData(jsonEncode(response));
      state = state.copyWith(user: userData);
    } catch (e) {
      state = state.copyWith(error: e.toString());
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

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.logout();
      await _storage.clearAll();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scheduling_mobile/app/configs/theme.dart';
import 'package:scheduling_mobile/providers/auth_provider.dart';
import 'package:scheduling_mobile/services/api_service.dart';
import 'package:scheduling_mobile/services/secure_storage_service.dart';

class InMemorySecureStorageService extends SecureStorageService {
  String? _token;
  String? _refreshToken;
  String? _userData;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  @override
  Future<void> clearRefreshToken() async {
    _refreshToken = null;
  }

  @override
  Future<void> saveUserData(String userData) async {
    _userData = userData;
  }

  @override
  Future<String?> getUserData() async {
    return _userData;
  }

  @override
  Future<void> clearAll() async {
    _token = null;
    _refreshToken = null;
    _userData = null;
  }
}

Widget buildAuthHarness({
  required Widget child,
  required double width,
  required double textScale,
  bool disableAnimations = false,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => AuthNotifier(
          ApiService(enableNetworkLogs: false),
          InMemorySecureStorageService(),
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, pageChild) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(width, 780),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
            accessibleNavigation: disableAnimations,
          ),
          child: pageChild!,
        );
      },
      home: child,
    ),
  );
}

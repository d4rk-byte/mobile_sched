// lib/providers/api_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

const String _defaultDesktopBaseUrl = 'http://127.0.0.1:8000/api';
const String _defaultAndroidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';
const String _defaultWebBaseUrl = 'http://localhost:8000/api';

final apiBaseUrlProvider = Provider<String>((ref) {
  final fromDefine = const String.fromEnvironment('API_BASE_URL').trim();
  if (fromDefine.isNotEmpty) {
    return _normalizeApiBaseUrl(fromDefine);
  }

  if (kIsWeb) {
    return _defaultWebBaseUrl;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android emulator routes localhost through 10.0.2.2.
      return _defaultAndroidEmulatorBaseUrl;
    case TargetPlatform.iOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.fuchsia:
      return _defaultDesktopBaseUrl;
  }
});

String _normalizeApiBaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('/api')) {
    return trimmed;
  }
  if (trimmed.endsWith('/')) {
    return '${trimmed}api';
  }
  return '$trimmed/api';
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);

  return ApiService(
    baseUrl: baseUrl,
  );
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

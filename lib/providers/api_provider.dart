// lib/providers/api_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    baseUrl: 'http://localhost:8000/api', // Change based on environment
  );
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

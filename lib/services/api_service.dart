// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class ApiService {
  late Dio _dio;
  final String baseUrl;
  final Logger _logger = Logger();

  ApiService({
    this.baseUrl = 'http://localhost:8000/api', // Configure per environment
  }) {
    _setupDio();
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token if available
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.message}');
          if (error.response?.statusCode == 401) {
            // Handle unauthorized
            _handleUnauthorized();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  void _handleUnauthorized() {
    // Emit event or notify app to redirect to login
    // This can be handled via a stream or global state management
  }

  // AUTHENTICATION
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
      await clearToken();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FACULTY ENDPOINTS
  Future<Map<String, dynamic>> getFacultyDashboard() async {
    try {
      final response = await _dio.get('/faculty/dashboard');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFacultyProfile() async {
    try {
      final response = await _dio.get('/faculty/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateFacultyProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '/faculty/profile',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await _dio.put(
        '/faculty/profile/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFacultySchedule(String? semester) async {
    try {
      final params = semester != null ? {'semester': semester} : null;
      final response = await _dio.get(
        '/faculty/schedule',
        queryParameters: params,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getWeeklySchedule(String? semester) async {
    try {
      final params = semester != null ? {'semester': semester} : null;
      final response = await _dio.get(
        '/faculty/schedule/weekly',
        queryParameters: params,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFacultyClasses(String? semester) async {
    try {
      final params = semester != null ? {'semester': semester} : null;
      final response = await _dio.get(
        '/faculty/classes',
        queryParameters: params,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateEnrolledStudents(
    int classId,
    int enrolledStudents,
  ) async {
    try {
      final response = await _dio.patch(
        '/faculty/classes/$classId/enrolled-students',
        data: {
          'enrolled_students': enrolledStudents,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> listRooms({
    String? search,
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get(
        '/faculty/rooms',
        queryParameters: {
          'search': search,
          'limit': limit,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> listScheduleChangeRequests({
    String? status,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/faculty/schedule-change-requests',
        queryParameters: {
          'status': status,
          'limit': limit,
        },
      );
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkScheduleChangeConflict(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/faculty/schedule-change-requests/check-conflict',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createScheduleChangeRequest(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/faculty/schedule-change-requests',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getScheduleChangeRequest(int id) async {
    try {
      final response = await _dio.get('/faculty/schedule-change-requests/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelScheduleChangeRequest(int id) async {
    try {
      final response = await _dio.post(
        '/faculty/schedule-change-requests/$id/cancel',
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/faculty/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get('/faculty/notifications/unread-count');
      return response.data['unread_count'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(int id) async {
    try {
      final response = await _dio.post('/faculty/notifications/$id/read');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    try {
      final response = await _dio.post('/faculty/notifications/read-all');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteNotification(int id) async {
    try {
      final response = await _dio.delete('/faculty/notifications/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> exportSchedulePdf(String? semester) async {
    try {
      final response = await _dio.get(
        '/faculty/schedule/export-pdf',
        queryParameters: semester != null ? {'semester': semester} : null,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> exportTeachingLoadPdf(String? semester) async {
    try {
      final response = await _dio.get(
        '/faculty/schedule/teaching-load-pdf',
        queryParameters: semester != null ? {'semester': semester} : null,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    String message = 'An error occurred';

    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ??
            data['error']?['message'] ??
            error.message ??
            'Server error';
      } else {
        message = error.message ?? 'Server error';
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Receive timeout';
    } else {
      message = error.message ?? 'An error occurred';
    }

    return message;
  }
}

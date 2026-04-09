// lib/services/api_service.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ApiService {
  late Dio _dio;
  final String baseUrl;
  final Logger _logger = Logger();
  final bool _enableNetworkLogs;
  
  // In-memory token storage (set by auth provider from secure storage)
  String? _token;
  
  // Stream to notify listeners of unauthorized errors (401)
  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  ApiService({
    this.baseUrl = 'http://localhost:8000/api', // Configure per environment
    bool? enableNetworkLogs,
  }) : _enableNetworkLogs = enableNetworkLogs ?? kDebugMode {
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
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          _logRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          return handler.next(response);
        },
        onError: (error, handler) {
          _logError(error);
          if (error.response?.statusCode == 401) {
            // Handle unauthorized - notify listeners to force logout
            _handleUnauthorized();
          }
          return handler.next(error);
        },
      ),
    );

    if (_enableNetworkLogs) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          error: true,
          logPrint: (object) => _logger.d(object.toString()),
        ),
      );
    }
  }

  Future<void> setToken(String token) async {
    _token = token;
  }

  Future<void> clearToken() async {
    _token = null;
  }

  void _handleUnauthorized() {
    // Emit event to notify auth provider to redirect to login
    _unauthorizedController.add(null);
  }
  
  void dispose() {
    _unauthorizedController.close();
  }

  // AUTHENTICATION
  Future<Map<String, dynamic>> login(String username, String password) async {
    final payload = {
      'username': username,
      'password': password,
    };

    try {
      final response = await _dio.post('/auth/login', data: payload);
      return response.data;
    } on DioException catch (e) {
      // Backward compatibility for older auth route names.
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          final fallbackResponse = await _dio.post('/login', data: payload);
          return fallbackResponse.data;
        } on DioException catch (fallbackError) {
          throw _handleError(fallbackError);
        }
      }
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

  Future<Map<String, dynamic>> register({
    required String username,
    required String employeeId,
    required String email,
    required String password,
  }) async {
    final payload = {
      'username': username,
      'employee_id': employeeId,
      'email': email,
      'password': password,
    };

    try {
      final response = await _dio.post('/auth/register', data: payload);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkRegisterAvailability({
    required String field,
    required String value,
  }) async {
    try {
      final response = await _dio.get(
        '/auth/register/check-availability',
        queryParameters: {field: value},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getColleges() async {
    try {
      final response = await _dio.get('/colleges');
      final data = response.data['data'] ?? response.data ?? [];
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDepartments({int? collegeId}) async {
    try {
      final response = await _dio.get(
        '/departments',
        queryParameters: collegeId != null ? {'college_id': collegeId} : null,
      );
      final data = response.data['data'] ?? response.data ?? [];
      return List<Map<String, dynamic>>.from(data);
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
      final response = await _dio.get(
        '/faculty/schedule',
        queryParameters: _buildQueryParameters({'semester': semester}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getWeeklySchedule(String? semester) async {
    try {
      final response = await _dio.get(
        '/faculty/schedule/weekly',
        queryParameters: _buildQueryParameters({'semester': semester}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFacultyClasses(String? semester) async {
    try {
      final response = await _dio.get(
        '/faculty/classes',
        queryParameters: _buildQueryParameters({'semester': semester}),
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
        queryParameters: _buildQueryParameters({
          'search': search,
          'limit': limit,
        }),
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
        queryParameters: _buildQueryParameters({
          'status': status,
          'limit': limit,
        }),
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
        queryParameters: _buildQueryParameters({'semester': semester}),
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
        queryParameters: _buildQueryParameters({'semester': semester}),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic>? _buildQueryParameters(
      Map<String, dynamic?> parameters) {
    final cleaned = <String, dynamic>{};

    parameters.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (value is String && value.trim().isEmpty) {
        return;
      }
      cleaned[key] = value;
    });

    return cleaned.isEmpty ? null : cleaned;
  }

  void _logRequest(RequestOptions options) {
    if (!_enableNetworkLogs) {
      return;
    }

    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }

    _logger.d(
      'Request: ${options.method} ${options.uri}\n'
      'Headers: $headers\n'
      'Query: ${options.queryParameters}\n'
      'Body: ${options.data}',
    );
  }

  void _logResponse(Response<dynamic> response) {
    if (!_enableNetworkLogs) {
      return;
    }

    _logger.d(
      'Response: ${response.statusCode} ${response.requestOptions.uri}\n'
      'Data: ${response.data}',
    );
  }

  void _logError(DioException error) {
    if (!_enableNetworkLogs) {
      return;
    }

    _logger.e(
      'Error: ${error.response?.statusCode ?? error.type.name} '
      '${error.requestOptions.method} ${error.requestOptions.uri}\n'
      'Request body: ${error.requestOptions.data}\n'
      'Query: ${error.requestOptions.queryParameters}\n'
      'Response: ${error.response?.data}\n'
      'Message: ${error.message}',
    );
  }

  String _extractErrorMessage(dynamic data) {
    if (data is String && data.isNotEmpty) {
      return data;
    }

    if (data is! Map<String, dynamic>) {
      return 'Server error';
    }

    final directMessage = data['message'] ?? data['error']?['message'];
    if (directMessage is String && directMessage.isNotEmpty) {
      return directMessage;
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is String && value.isNotEmpty) {
          return value;
        }
        if (value is List && value.isNotEmpty && value.first is String) {
          final first = value.first as String;
          if (first.isNotEmpty) {
            return first;
          }
        }
      }
    }

    return 'Server error';
  }

  String _handleError(DioException error) {
    String message = 'An error occurred';

    if (error.response != null) {
      final extractedMessage = _extractErrorMessage(error.response!.data);
      message = extractedMessage == 'Server error'
          ? (error.message ?? 'Server error')
          : extractedMessage;
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

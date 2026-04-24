import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_mobile/services/api_service.dart';

void main() {
  group('ApiService unauthorized logout path filtering', () {
    late ApiService service;

    setUp(() {
      service = ApiService(enableNetworkLogs: false);
    });

    tearDown(() {
      service.dispose();
    });

    test('returns false when there is no token', () {
      final shouldTrigger = service.shouldTriggerUnauthorizedLogoutForPath(
        path: '/faculty/dashboard',
        hasToken: false,
      );

      expect(shouldTrigger, isFalse);
    });

    test('returns false for auth endpoints even with token', () {
      const authPaths = <String>[
        '/auth/login',
        '/login',
        '/auth/register',
        '/auth/register/check-availability',
        '/auth/logout',
      ];

      for (final path in authPaths) {
        final shouldTrigger = service.shouldTriggerUnauthorizedLogoutForPath(
          path: path,
          hasToken: true,
        );

        expect(shouldTrigger, isFalse, reason: 'Expected false for $path');
      }
    });

    test('returns false for prefixed auth endpoints with token', () {
      const prefixedAuthPaths = <String>[
        '/api/auth/login',
        '/v1/auth/register',
        '/proxy/auth/register/check-availability',
        '/gateway/auth/logout',
      ];

      for (final path in prefixedAuthPaths) {
        final shouldTrigger = service.shouldTriggerUnauthorizedLogoutForPath(
          path: path,
          hasToken: true,
        );

        expect(shouldTrigger, isFalse, reason: 'Expected false for $path');
      }
    });

    test('returns true for protected endpoints with token', () {
      const protectedPaths = <String>[
        '/faculty/dashboard',
        '/faculty/notifications',
        '/faculty/profile',
      ];

      for (final path in protectedPaths) {
        final shouldTrigger = service.shouldTriggerUnauthorizedLogoutForPath(
          path: path,
          hasToken: true,
        );

        expect(shouldTrigger, isTrue, reason: 'Expected true for $path');
      }
    });

    test('matches paths case-insensitively', () {
      final authShouldNotTrigger =
          service.shouldTriggerUnauthorizedLogoutForPath(
        path: '/AUTH/LOGIN',
        hasToken: true,
      );
      final protectedShouldTrigger =
          service.shouldTriggerUnauthorizedLogoutForPath(
        path: '/FACULTY/DASHBOARD',
        hasToken: true,
      );

      expect(authShouldNotTrigger, isFalse);
      expect(protectedShouldTrigger, isTrue);
    });
  });
}

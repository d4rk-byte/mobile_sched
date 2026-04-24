import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_mobile/services/api_service.dart';

DioException _buildTimeoutError() {
  return DioException(
    requestOptions: RequestOptions(path: '/faculty/notifications'),
    type: DioExceptionType.connectionTimeout,
    message: 'Connection timeout',
  );
}

void main() {
  group('ApiService notification request guard', () {
    late ApiService service;

    tearDown(() {
      service.dispose();
    });

    test('de-duplicates concurrent requests for the same key', () async {
      service = ApiService(enableNetworkLogs: false);

      final responseCompleter = Completer<int>();
      var requestExecutions = 0;

      Future<int> guardedRequest() async {
        requestExecutions++;
        return responseCompleter.future;
      }

      final first = service.runNotificationRequestGuardForTesting<int>(
        requestKey: 'notifications:unread-count',
        request: guardedRequest,
      );
      final second = service.runNotificationRequestGuardForTesting<int>(
        requestKey: 'notifications:unread-count',
        request: guardedRequest,
      );

      expect(requestExecutions, 1);

      responseCompleter.complete(7);

      expect(await first, 7);
      expect(await second, 7);
      expect(requestExecutions, 1);
    });

    test('applies cooldown after transient failure and blocks immediate retry',
        () async {
      service = ApiService(
        enableNetworkLogs: false,
        notificationFailureCooldown: const Duration(milliseconds: 80),
      );

      var failingExecutions = 0;
      Future<int> failingRequest() async {
        failingExecutions++;
        throw _buildTimeoutError();
      }

      await expectLater(
        service.runNotificationRequestGuardForTesting<int>(
          requestKey: 'notifications:20:0',
          request: failingRequest,
        ),
        throwsA(
          predicate(
            (error) =>
                error is String && error.toLowerCase().contains('timeout'),
          ),
        ),
      );

      var blockedExecutions = 0;
      await expectLater(
        service.runNotificationRequestGuardForTesting<int>(
          requestKey: 'notifications:20:0',
          request: () async {
            blockedExecutions++;
            return 1;
          },
        ),
        throwsA(
          predicate(
            (error) =>
                error is String && error.toLowerCase().contains('timeout'),
          ),
        ),
      );

      expect(failingExecutions, 1);
      expect(blockedExecutions, 0);
    });

    test('cooldown expires and success clears cooldown for subsequent calls',
        () async {
      service = ApiService(
        enableNetworkLogs: false,
        notificationFailureCooldown: const Duration(milliseconds: 60),
      );

      await expectLater(
        service.runNotificationRequestGuardForTesting<int>(
          requestKey: 'notifications:unread-count',
          request: () async => throw _buildTimeoutError(),
        ),
        throwsA(isA<String>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      var successExecutions = 0;
      final firstSuccess = await service.runNotificationRequestGuardForTesting(
        requestKey: 'notifications:unread-count',
        request: () async {
          successExecutions++;
          return 11;
        },
      );

      final secondSuccess = await service.runNotificationRequestGuardForTesting(
        requestKey: 'notifications:unread-count',
        request: () async {
          successExecutions++;
          return 12;
        },
      );

      expect(firstSuccess, 11);
      expect(secondSuccess, 12);
      expect(successExecutions, 2);
    });
  });
}

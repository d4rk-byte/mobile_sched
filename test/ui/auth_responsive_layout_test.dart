import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_mobile/ui/auth/screens/register_page.dart';
import 'package:scheduling_mobile/ui/auth/screens/signin_page.dart';
import 'package:scheduling_mobile/ui/auth/screens/welcome_page.dart';
import 'auth_test_harness.dart';

class _ResponsiveScenario {
  const _ResponsiveScenario(this.width, this.textScale);

  final double width;
  final double textScale;
}

Finder _findTextContaining(String expectedText) {
  return find.byWidgetPredicate(
    (widget) {
      if (widget is Text) {
        final content = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        return content.contains(expectedText);
      }

      if (widget is RichText) {
        return widget.text.toPlainText().contains(expectedText);
      }

      return false;
    },
    description: 'Text or RichText containing "$expectedText"',
  );
}

Future<void> _expectResponsiveLayout({
  required WidgetTester tester,
  required Widget page,
  required _ResponsiveScenario scenario,
  required List<String> expectedTexts,
}) async {
  await tester.pumpWidget(
    buildAuthHarness(
      child: page,
      width: scenario.width,
      textScale: scenario.textScale,
    ),
  );

  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();

  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason:
        'Expected no layout exceptions at width=${scenario.width}, textScale=${scenario.textScale}.',
  );

  for (final expectedText in expectedTexts) {
    expect(
      _findTextContaining(expectedText),
      findsWidgets,
      reason:
          'Expected to find "$expectedText" at width=${scenario.width}, textScale=${scenario.textScale}.',
    );
  }
}

Future<void> _pumpScenario({
  required WidgetTester tester,
  required Widget page,
  required _ResponsiveScenario scenario,
}) async {
  await tester.binding.setSurfaceSize(Size(scenario.width, 780));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    buildAuthHarness(
      child: page,
      width: scenario.width,
      textScale: scenario.textScale,
    ),
  );

  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();

  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason:
        'Expected no layout exceptions at width=${scenario.width}, textScale=${scenario.textScale}.',
  );
}

Future<void> _expectCanScrollToText({
  required WidgetTester tester,
  required Widget page,
  required _ResponsiveScenario scenario,
  required String targetText,
}) async {
  await _pumpScenario(tester: tester, page: page, scenario: scenario);

  final targetFinder = _findTextContaining(targetText).first;
  final scrollableFinder = find.byType(Scrollable).first;

  await tester.scrollUntilVisible(
    targetFinder,
    120,
    scrollable: scrollableFinder,
    maxScrolls: 30,
  );
  await tester.pumpAndSettle();

  expect(
    targetFinder,
    findsWidgets,
    reason:
        'Expected to be able to scroll to "$targetText" at width=${scenario.width}, textScale=${scenario.textScale}.',
  );
}

void main() {
  const scenarios = <_ResponsiveScenario>[
    _ResponsiveScenario(320, 1.4),
    _ResponsiveScenario(280, 1.8),
  ];

  for (final scenario in scenarios) {
    testWidgets(
      'WelcomePage handles width=${scenario.width}, textScale=${scenario.textScale}',
      (tester) async {
        await _expectResponsiveLayout(
          tester: tester,
          page: const WelcomePage(),
          scenario: scenario,
          expectedTexts: const [
            'Faculty Scheduling\nSystem',
            'Register',
            'Sign In',
          ],
        );
      },
    );

    testWidgets(
      'SignInPage handles width=${scenario.width}, textScale=${scenario.textScale}',
      (tester) async {
        await _expectResponsiveLayout(
          tester: tester,
          page: const SignInPage(),
          scenario: scenario,
          expectedTexts: const [
            'Sign In',
            'Email or Username',
            'Password',
            'Keep me logged in',
          ],
        );
      },
    );

    testWidgets(
      'RegisterPage handles width=${scenario.width}, textScale=${scenario.textScale}',
      (tester) async {
        await _expectResponsiveLayout(
          tester: tester,
          page: const RegisterPage(),
          scenario: scenario,
          expectedTexts: const [
            'Sign Up',
            'Username',
            'Employee ID',
            'Terms and Conditions',
          ],
        );
      },
    );
  }

  const interactionScenario = _ResponsiveScenario(320, 1.4);
  const largeTextScenario = _ResponsiveScenario(280, 1.8);

  testWidgets('WelcomePage Register CTA navigates to RegisterPage', (
    tester,
  ) async {
    await _pumpScenario(
      tester: tester,
      page: const WelcomePage(),
      scenario: interactionScenario,
    );

    final registerFinder = find.text('Register').first;
    await tester.ensureVisible(registerFinder);
    await tester.tap(registerFinder);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('SignInPage Sign Up prompt navigates to RegisterPage', (
    tester,
  ) async {
    await _pumpScenario(
      tester: tester,
      page: const SignInPage(),
      scenario: interactionScenario,
    );

    final signUpFinder = _findTextContaining('Sign Up').first;
    await tester.ensureVisible(signUpFinder);
    await tester.tap(signUpFinder);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('RegisterPage Sign In prompt navigates to SignInPage', (
    tester,
  ) async {
    await _pumpScenario(
      tester: tester,
      page: const RegisterPage(),
      scenario: interactionScenario,
    );

    final signInFinder = _findTextContaining('Sign In').first;
    await tester.ensureVisible(signInFinder);
    await tester.tap(signInFinder);
    await tester.pumpAndSettle();

    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('SignInPage can scroll to bottom prompt at large text scale', (
    tester,
  ) async {
    await _expectCanScrollToText(
      tester: tester,
      page: const SignInPage(),
      scenario: largeTextScenario,
      targetText: 'Don\'t have an account?',
    );
  });

  testWidgets('RegisterPage can scroll to bottom prompt at large text scale', (
    tester,
  ) async {
    await _expectCanScrollToText(
      tester: tester,
      page: const RegisterPage(),
      scenario: largeTextScenario,
      targetText: 'Already have an account?',
    );
  });
}

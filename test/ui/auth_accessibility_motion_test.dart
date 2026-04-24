import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_mobile/ui/auth/screens/register_page.dart';
import 'package:scheduling_mobile/ui/auth/screens/signin_page.dart';
import 'package:scheduling_mobile/ui/auth/screens/welcome_page.dart';
import 'package:scheduling_mobile/ui/auth/widgets/auth_staggered_entrance.dart';
import 'auth_test_harness.dart';

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

Finder _findSemanticButton({required String label, required String hint}) {
  return find.byWidgetPredicate(
    (widget) {
      return widget is Semantics &&
          widget.properties.label == label &&
          widget.properties.hint == hint &&
          widget.properties.button == true;
    },
    description: 'Semantics button label="$label" hint="$hint"',
  );
}

Finder _findFocusedEditableText() {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.focusNode.hasFocus,
    description: 'Focused EditableText',
  );
}

Future<void> _sendShiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

Future<void> _activateAfterTabbingUntilMessage({
  required WidgetTester tester,
  required LogicalKeyboardKey activationKey,
  required String expectedMessage,
  int maxTabs = 16,
}) async {
  for (var i = 0; i < maxTabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(activationKey);
    await tester.pumpAndSettle();

    if (find.text(expectedMessage).evaluate().isNotEmpty) {
      return;
    }
  }

  fail(
    'Expected keyboard activation to produce "$expectedMessage" within $maxTabs tab steps.',
  );
}

Future<void> _toggleCheckboxWithSpaceAfterTabbing({
  required WidgetTester tester,
  required Finder checkboxFinder,
  int maxTabs = 24,
}) async {
  final initialValue = tester.widget<Checkbox>(checkboxFinder).value ?? false;

  for (var i = 0; i < maxTabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    final currentValue = tester.widget<Checkbox>(checkboxFinder).value ?? false;
    if (currentValue != initialValue) {
      return;
    }
  }

  fail(
    'Expected Space key to toggle checkbox within $maxTabs tab steps.',
  );
}

Future<void> _activateAfterKeyboardTraversalUntilDestination({
  required WidgetTester tester,
  required Finder homeFinder,
  required Finder destinationFinder,
  required LogicalKeyboardKey activationKey,
  bool reverseTraversal = false,
  int traversalStepsPerAttempt = 1,
  int maxAttempts = 8,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    for (var step = 0; step < traversalStepsPerAttempt; step++) {
      if (reverseTraversal) {
        await _sendShiftTab(tester);
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
    }

    await tester.sendKeyEvent(activationKey);
    await tester.pumpAndSettle();

    if (destinationFinder.evaluate().isNotEmpty) {
      return;
    }

    if (homeFinder.evaluate().isEmpty) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  }

  fail(
    'Expected keyboard traversal plus activation to reach destination within $maxAttempts attempts.',
  );
}

Future<void> _activateAfterTabSweepFromStarter({
  required WidgetTester tester,
  required Finder startFocusFinder,
  required Finder destinationFinder,
  required LogicalKeyboardKey activationKey,
  int maxTabs = 24,
}) async {
  for (var tabCount = 1; tabCount <= maxTabs; tabCount++) {
    await tester.ensureVisible(startFocusFinder);
    await tester.tap(startFocusFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    for (var i = 0; i < tabCount; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    await tester.sendKeyEvent(activationKey);
    await tester.pumpAndSettle();

    if (destinationFinder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail(
    'Expected keyboard activation to reach destination within $maxTabs tab sweep attempts.',
  );
}

bool _isPrimaryFocusWithinFinder(WidgetTester tester, Finder finder) {
  final focusedContext = tester.binding.focusManager.primaryFocus?.context;
  if (focusedContext == null) {
    return false;
  }

  final targetElements = finder.evaluate().toList();
  if (targetElements.isEmpty) {
    return false;
  }

  final target = targetElements.first;
  if (focusedContext == target) {
    return true;
  }

  var withinTarget = false;
  focusedContext.visitAncestorElements((ancestor) {
    if (ancestor == target) {
      withinTarget = true;
      return false;
    }
    return true;
  });

  return withinTarget;
}

Future<void> _focusAndActivateTargetByTabTraversal({
  required WidgetTester tester,
  required Finder startFocusFinder,
  required Finder targetFinder,
  required LogicalKeyboardKey activationKey,
  int maxTabs = 80,
}) async {
  final starter = startFocusFinder.first;
  await tester.ensureVisible(starter);
  await tester.tap(starter, warnIfMissed: false);
  await tester.pumpAndSettle();

  for (var i = 0; i < maxTabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    if (_isPrimaryFocusWithinFinder(tester, targetFinder)) {
      await tester.sendKeyEvent(activationKey);
      await tester.pumpAndSettle();
      return;
    }
  }

  fail(
    'Expected tab traversal to focus target control within $maxTabs tab steps.',
  );
}

Future<void> _pumpPage({
  required WidgetTester tester,
  required Widget page,
  double width = 320,
  double textScale = 1.0,
  bool disableAnimations = false,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 780));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    buildAuthHarness(
      child: page,
      width: width,
      textScale: textScale,
      disableAnimations: disableAnimations,
    ),
  );

  if (settle) {
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  final exception = tester.takeException();
  expect(exception, isNull);
}

Future<void> _scrollToText(
  WidgetTester tester,
  String text,
) async {
  final targetFinder = _findTextContaining(text).first;
  await tester.scrollUntilVisible(
    targetFinder,
    120,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 30,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AuthStaggeredEntrance bypasses wrappers when reduced motion is enabled',
    (tester) async {
      await _pumpPage(
        tester: tester,
        disableAnimations: true,
        page: const Scaffold(
          body: AuthStaggeredEntrance(
            delay: Duration(milliseconds: 220),
            child: Text('Motion Probe'),
          ),
        ),
      );

      expect(find.text('Motion Probe'), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.byType(AnimatedSlide), findsNothing);
    },
  );

  testWidgets(
    'AuthStaggeredEntrance keeps wrappers when motion is enabled',
    (tester) async {
      await _pumpPage(
        tester: tester,
        disableAnimations: false,
        page: const Scaffold(
          body: AuthStaggeredEntrance(
            delay: Duration(milliseconds: 220),
            child: Text('Motion Probe'),
          ),
        ),
      );

      expect(find.text('Motion Probe'), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsOneWidget);
      expect(find.byType(AnimatedSlide), findsOneWidget);
    },
  );

  testWidgets(
    'WelcomePage disables entrance animation wrappers when reduced motion is enabled',
    (tester) async {
      await _pumpPage(
        tester: tester,
        page: const WelcomePage(),
        disableAnimations: true,
      );

      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.byType(AnimatedSlide), findsNothing);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    },
  );

  testWidgets(
    'SignInPage reduced motion allows immediate social CTA interaction',
    (tester) async {
      await _pumpPage(
        tester: tester,
        page: const SignInPage(),
        disableAnimations: true,
        settle: false,
      );

      await tester.tap(find.text('Sign in with Google').first);
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Google is not available yet.'),
          findsOneWidget);
    },
  );

  testWidgets(
    'RegisterPage reduced motion allows immediate social CTA interaction',
    (tester) async {
      await _pumpPage(
        tester: tester,
        page: const RegisterPage(),
        disableAnimations: true,
        settle: false,
      );

      await tester.tap(find.text('Sign up with Google').first);
      await tester.pumpAndSettle();

      expect(find.text('Sign up with Google is not available yet.'),
          findsOneWidget);
    },
  );

  testWidgets(
      'SignInPage large text reduced motion keyboard Enter activates social CTA',
      (tester) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _scrollToText(tester, 'Email or Username');

    await _focusAndActivateTargetByTabTraversal(
      tester: tester,
      startFocusFinder: find.byType(TextField),
      targetFinder: find.widgetWithText(TextButton, 'Sign in with Google'),
      activationKey: LogicalKeyboardKey.enter,
      maxTabs: 80,
    );

    expect(
        find.text('Sign in with Google is not available yet.'), findsOneWidget);
  });

  testWidgets(
      'RegisterPage large text reduced motion keyboard Space activates social CTA',
      (tester) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _scrollToText(tester, 'Username');

    await _focusAndActivateTargetByTabTraversal(
      tester: tester,
      startFocusFinder: find.byType(TextField),
      targetFinder: find.widgetWithText(TextButton, 'Sign up with Google'),
      activationKey: LogicalKeyboardKey.space,
      maxTabs: 100,
    );

    expect(
        find.text('Sign up with Google is not available yet.'), findsOneWidget);
  });

  testWidgets('SignInPage exposes semantics for social auth CTAs', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const SignInPage(),
        width: 320,
        textScale: 1.4,
      );

      expect(
        find.bySemanticsLabel(RegExp('Sign in with Google')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp('Sign in with X')),
        findsWidgets,
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('RegisterPage exposes semantics for social auth CTAs', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const RegisterPage(),
        width: 320,
        textScale: 1.4,
      );

      expect(
        find.bySemanticsLabel(RegExp('Sign up with Google')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp('Sign up with X')),
        findsWidgets,
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('SignInPage social auth semantics include unavailable hint', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 320,
      textScale: 1.4,
    );

    expect(
      _findSemanticButton(
        label: 'Sign in with Google',
        hint: 'Currently unavailable',
      ),
      findsOneWidget,
    );
    expect(
      _findSemanticButton(
        label: 'Sign in with X',
        hint: 'Currently unavailable',
      ),
      findsOneWidget,
    );
  });

  testWidgets('RegisterPage social auth semantics include unavailable hint', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 320,
      textScale: 1.4,
    );

    expect(
      _findSemanticButton(
        label: 'Sign up with Google',
        hint: 'Currently unavailable',
      ),
      findsOneWidget,
    );
    expect(
      _findSemanticButton(
        label: 'Sign up with X',
        hint: 'Currently unavailable',
      ),
      findsOneWidget,
    );
  });

  testWidgets('WelcomePage exposes semantics for main auth CTAs', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const WelcomePage(),
        width: 320,
        textScale: 1.0,
      );

      expect(find.bySemanticsLabel(RegExp('Register')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Sign In')), findsWidgets);
      expect(
        _findSemanticButton(
          label: 'Register',
          hint: 'Navigates to registration',
        ),
        findsOneWidget,
      );
      expect(
        _findSemanticButton(
          label: 'Sign In',
          hint: 'Navigates to sign in',
        ),
        findsOneWidget,
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('WelcomePage keyboard Enter activates Register CTA', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 320,
      textScale: 1.0,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(RegisterPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: false,
      traversalStepsPerAttempt: 1,
    );

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('WelcomePage keyboard Enter activates Sign In CTA', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 320,
      textScale: 1.0,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(SignInPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: true,
      traversalStepsPerAttempt: 1,
    );

    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('WelcomePage large text keyboard Enter activates Register CTA', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 280,
      textScale: 1.8,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(RegisterPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: false,
      traversalStepsPerAttempt: 1,
      maxAttempts: 10,
    );

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('WelcomePage large text keyboard Enter activates Sign In CTA', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 280,
      textScale: 1.8,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(SignInPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: true,
      traversalStepsPerAttempt: 1,
      maxAttempts: 10,
    );

    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets(
      'WelcomePage reduced motion keyboard Enter activates Register CTA', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      disableAnimations: true,
      settle: false,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(RegisterPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: false,
      traversalStepsPerAttempt: 1,
    );

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets(
      'WelcomePage keyboard Shift+Tab twice then Enter activates Register CTA',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 320,
      textScale: 1.0,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(RegisterPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: true,
      traversalStepsPerAttempt: 2,
    );

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('WelcomePage keyboard Shift+Tab then Enter activates Sign In CTA',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 320,
      textScale: 1.0,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(SignInPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: true,
      traversalStepsPerAttempt: 1,
    );

    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets(
      'WelcomePage large text reduced motion keyboard Enter activates Register CTA',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(RegisterPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: false,
      traversalStepsPerAttempt: 1,
      maxAttempts: 10,
    );

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets(
      'WelcomePage large text reduced motion keyboard Enter activates Sign In CTA',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(SignInPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: true,
      traversalStepsPerAttempt: 1,
      maxAttempts: 10,
    );

    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('SignInPage exposes semantics for back link label', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const SignInPage(),
        width: 320,
        textScale: 1.0,
      );

      expect(
        find.bySemanticsLabel(RegExp('Back to dashboard')),
        findsWidgets,
      );
      expect(
        _findSemanticButton(
          label: 'Back to dashboard',
          hint: 'Navigates back to dashboard',
        ),
        findsOneWidget,
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('RegisterPage exposes semantics for back link label', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const RegisterPage(),
        width: 320,
        textScale: 1.0,
      );

      expect(
        find.bySemanticsLabel(RegExp('Back to dashboard')),
        findsWidgets,
      );
      expect(
        _findSemanticButton(
          label: 'Back to dashboard',
          hint: 'Navigates back to dashboard',
        ),
        findsOneWidget,
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('SignInPage sign-up prompt is semantic and navigates', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const SignInPage(),
        width: 320,
        textScale: 1.4,
      );

      await _scrollToText(tester, 'Sign Up');
      expect(find.bySemanticsLabel(RegExp('Sign Up')), findsWidgets);
      expect(
        _findSemanticButton(
          label: 'Sign Up',
          hint: 'Navigates to registration',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('RegisterPage sign-in prompt is semantic and navigates', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const RegisterPage(),
        width: 320,
        textScale: 1.4,
      );

      await _scrollToText(tester, 'Sign In');
      expect(find.bySemanticsLabel(RegExp('Sign In')), findsWidgets);
      expect(
        _findSemanticButton(
          label: 'Sign In',
          hint: 'Navigates to sign in',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Sign In').first);
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets(
      'SignInPage large text reduced motion keyboard Enter activates sign-up prompt',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _scrollToText(tester, 'Sign Up');

    await _activateAfterTabSweepFromStarter(
      tester: tester,
      startFocusFinder: find.byType(TextField).first,
      destinationFinder: find.byType(RegisterPage),
      activationKey: LogicalKeyboardKey.enter,
      maxTabs: 28,
    );

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets(
      'RegisterPage large text reduced motion keyboard Enter activates sign-in prompt',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _scrollToText(tester, 'Sign In');

    await _activateAfterTabSweepFromStarter(
      tester: tester,
      startFocusFinder: find.byType(TextField).first,
      destinationFinder: find.byType(SignInPage),
      activationKey: LogicalKeyboardKey.enter,
      maxTabs: 36,
    );

    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets(
      'SignInPage large text reduced motion keyboard Enter activates back link',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(SignInPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: true,
      traversalStepsPerAttempt: 1,
      maxAttempts: 12,
    );
    expect(find.byType(SignInPage), findsOneWidget);

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(SignInPage),
      destinationFinder: find.byType(WelcomePage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: false,
      traversalStepsPerAttempt: 1,
      maxAttempts: 36,
    );

    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets(
      'RegisterPage large text reduced motion keyboard Enter activates back link',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const WelcomePage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(WelcomePage),
      destinationFinder: find.byType(RegisterPage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: false,
      traversalStepsPerAttempt: 1,
      maxAttempts: 12,
    );
    expect(find.byType(RegisterPage), findsOneWidget);

    await _activateAfterKeyboardTraversalUntilDestination(
      tester: tester,
      homeFinder: find.byType(RegisterPage),
      destinationFinder: find.byType(WelcomePage),
      activationKey: LogicalKeyboardKey.enter,
      reverseTraversal: false,
      traversalStepsPerAttempt: 1,
      maxAttempts: 44,
    );

    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets(
    'SignInPage reduced motion shows immediate primary-submit validation',
    (tester) async {
      await _pumpPage(
        tester: tester,
        page: const SignInPage(),
        disableAnimations: true,
        settle: false,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Sign In').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your email/username and password.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RegisterPage reduced motion shows immediate primary-submit validation',
    (tester) async {
      await _pumpPage(
        tester: tester,
        page: const RegisterPage(),
        disableAnimations: true,
        settle: false,
      );

      final submitFinder = find.widgetWithText(TextButton, 'Sign Up').first;
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Please agree to the Terms and Conditions.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('RegisterPage exposes semantics for terms and privacy text', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester: tester,
        page: const RegisterPage(),
        width: 320,
        textScale: 1.4,
      );

      await _scrollToText(tester, 'Terms and Conditions');
      expect(
          find.bySemanticsLabel(RegExp('Terms and Conditions')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Privacy Policy')), findsWidgets);
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets(
    'SignInPage forgot-password action is semantic and reachable at large text scale',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await _pumpPage(
          tester: tester,
          page: const SignInPage(),
          width: 280,
          textScale: 1.8,
        );

        await _scrollToText(tester, 'Forgot password?');
        expect(
          find.bySemanticsLabel(
              RegExp('Forgot password', caseSensitive: false)),
          findsWidgets,
        );
        expect(
          _findSemanticButton(
            label: 'Forgot password',
            hint: 'Currently unavailable',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Forgot password?').first);
        await tester.pumpAndSettle();

        expect(
            find.text('Forgot password is not available yet.'), findsOneWidget);
      } finally {
        semanticsHandle.dispose();
      }
    },
  );

  testWidgets('SignInPage keyboard Tab moves focus to password field', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 320,
      textScale: 1.0,
    );

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(2));

    await tester.tap(editableFields.first);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(_findFocusedEditableText(), findsOneWidget);
    expect(tester.widget<EditableText>(editableFields.at(1)).focusNode.hasFocus,
        isTrue);
  });

  testWidgets('RegisterPage keyboard Tab moves focus to employee ID field', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 320,
      textScale: 1.0,
    );

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(4));

    await tester.tap(editableFields.first);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(_findFocusedEditableText(), findsOneWidget);
    expect(tester.widget<EditableText>(editableFields.at(1)).focusNode.hasFocus,
        isTrue);
  });

  testWidgets(
      'SignInPage large text reduced motion keyboard Tab and Shift+Tab preserve field order',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
    );

    await _scrollToText(tester, 'Email or Username');

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(2));

    final identifierField = find.byType(TextField).first;
    await tester.ensureVisible(identifierField);
    await tester.tap(identifierField);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.at(1)).focusNode.hasFocus,
        isTrue);

    await _sendShiftTab(tester);
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);
  });

  testWidgets(
      'RegisterPage large text reduced motion keyboard Tab and Shift+Tab preserve field order',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
    );

    await _scrollToText(tester, 'Username');

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(4));

    final usernameField = find.byType(TextField).first;
    await tester.ensureVisible(usernameField);
    await tester.tap(usernameField);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.at(1)).focusNode.hasFocus,
        isTrue);

    await _sendShiftTab(tester);
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);
  });

  testWidgets(
      'SignInPage large text reduced motion keyboard focus cycles back to first control (no trap)',
      (tester) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
    );

    await _scrollToText(tester, 'Email or Username');

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(2));

    final identifierField = find.byType(TextField).first;
    await tester.ensureVisible(identifierField);
    await tester.tap(identifierField);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);

    var movedAway = false;
    var cycledBack = false;
    for (var i = 0; i < 80; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final firstHasFocus =
          tester.widget<EditableText>(editableFields.first).focusNode.hasFocus;

      if (!firstHasFocus) {
        movedAway = true;
      }

      if (movedAway && firstHasFocus) {
        cycledBack = true;
        break;
      }
    }

    expect(movedAway, isTrue, reason: 'Focus never left the first control.');
    expect(
      cycledBack,
      isTrue,
      reason:
          'Focus did not return to the first control after cycling tab order; potential focus trap.',
    );
  });

  testWidgets(
      'RegisterPage large text reduced motion keyboard focus cycles back to first control (no trap)',
      (tester) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
    );

    await _scrollToText(tester, 'Username');

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(4));

    final usernameField = find.byType(TextField).first;
    await tester.ensureVisible(usernameField);
    await tester.tap(usernameField);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);

    var movedAway = false;
    var cycledBack = false;
    for (var i = 0; i < 140; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final firstHasFocus =
          tester.widget<EditableText>(editableFields.first).focusNode.hasFocus;

      if (!firstHasFocus) {
        movedAway = true;
      }

      if (movedAway && firstHasFocus) {
        cycledBack = true;
        break;
      }
    }

    expect(movedAway, isTrue, reason: 'Focus never left the first control.');
    expect(
      cycledBack,
      isTrue,
      reason:
          'Focus did not return to the first control after cycling tab order; potential focus trap.',
    );
  });

  testWidgets(
      'SignInPage keyboard Shift+Tab moves focus back to identifier field', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 320,
      textScale: 1.0,
    );

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(2));

    await tester.tap(editableFields.at(1));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.at(1)).focusNode.hasFocus,
        isTrue);

    await _sendShiftTab(tester);

    expect(_findFocusedEditableText(), findsOneWidget);
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);
  });

  testWidgets(
      'RegisterPage keyboard Shift+Tab moves focus back to username field', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 320,
      textScale: 1.0,
    );

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(4));

    await tester.tap(editableFields.at(1));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editableFields.at(1)).focusNode.hasFocus,
        isTrue);

    await _sendShiftTab(tester);

    expect(_findFocusedEditableText(), findsOneWidget);
    expect(tester.widget<EditableText>(editableFields.first).focusNode.hasFocus,
        isTrue);
  });

  testWidgets('SignInPage keyboard Enter activates primary submit button', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      disableAnimations: true,
      settle: false,
    );

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(2));
    await tester.ensureVisible(editableFields.first);
    await tester.tap(editableFields.first);
    await tester.pumpAndSettle();

    await _activateAfterTabbingUntilMessage(
      tester: tester,
      activationKey: LogicalKeyboardKey.enter,
      expectedMessage: 'Please enter your email/username and password.',
    );

    expect(
      find.text('Please enter your email/username and password.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'SignInPage large text reduced motion keyboard Enter activates primary submit button',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const SignInPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    await _scrollToText(tester, 'Email or Username');
    final identifierField = find.byType(TextField).first;
    await tester.ensureVisible(identifierField);
    await tester.tap(identifierField);
    await tester.pumpAndSettle();

    await _activateAfterTabbingUntilMessage(
      tester: tester,
      activationKey: LogicalKeyboardKey.enter,
      expectedMessage: 'Please enter your email/username and password.',
      maxTabs: 32,
    );

    expect(
      find.text('Please enter your email/username and password.'),
      findsOneWidget,
    );
  });

  testWidgets('RegisterPage keyboard Space toggles terms checkbox', (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      disableAnimations: true,
      settle: false,
    );

    final checkboxFinder = find.byType(Checkbox).first;
    await tester.ensureVisible(checkboxFinder);
    expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(4));
    await tester.tap(editableFields.first);
    await tester.pumpAndSettle();

    await _toggleCheckboxWithSpaceAfterTabbing(
      tester: tester,
      checkboxFinder: checkboxFinder,
    );

    expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
  });

  testWidgets(
      'RegisterPage large text reduced motion keyboard Space toggles terms checkbox',
      (
    tester,
  ) async {
    await _pumpPage(
      tester: tester,
      page: const RegisterPage(),
      width: 280,
      textScale: 1.8,
      disableAnimations: true,
      settle: false,
    );

    final checkboxFinder = find.byType(Checkbox).first;
    await tester.ensureVisible(checkboxFinder);
    expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

    final editableFields = find.byType(EditableText);
    expect(editableFields, findsAtLeastNWidgets(4));
    await tester.tap(editableFields.first);
    await tester.pumpAndSettle();

    await _toggleCheckboxWithSpaceAfterTabbing(
      tester: tester,
      checkboxFinder: checkboxFinder,
      maxTabs: 40,
    );

    expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
  });

  testWidgets(
    'SignInPage keep-me-logged-in checkbox is semantic and toggles',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await _pumpPage(
          tester: tester,
          page: const SignInPage(),
          width: 280,
          textScale: 1.8,
        );

        await _scrollToText(tester, 'Keep me logged in');
        expect(
          find.bySemanticsLabel(
              RegExp('Keep me logged in', caseSensitive: false)),
          findsWidgets,
        );

        final checkboxFinder = find.byType(Checkbox).first;
        await tester.ensureVisible(checkboxFinder);

        expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

        await tester.tap(_findTextContaining('Keep me logged in').first);
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
      } finally {
        semanticsHandle.dispose();
      }
    },
  );

  testWidgets(
    'RegisterPage terms checkbox is semantic and toggles',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await _pumpPage(
          tester: tester,
          page: const RegisterPage(),
          width: 280,
          textScale: 1.8,
        );

        await _scrollToText(tester, 'Terms and Conditions');
        expect(
          find.bySemanticsLabel(
            RegExp(
              'Agree to the Terms and Conditions and Privacy Policy',
              caseSensitive: false,
            ),
          ),
          findsWidgets,
        );

        final checkboxFinder = find.byType(Checkbox).first;
        await tester.ensureVisible(checkboxFinder);

        expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

        await tester.tap(_findTextContaining('Terms and Conditions').first);
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
      } finally {
        semanticsHandle.dispose();
      }
    },
  );
}

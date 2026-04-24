import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../auth_constants.dart';
import '../widgets/widgets.dart';
import 'register_page.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  bool isPasswordVisible = true;
  bool keepMeLoggedIn = false;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(String message) {
    final normalized = message.trim();
    final lower = normalized.toLowerCase();

    if (lower.contains('invalid credentials')) {
      return 'Incorrect email/username or password.';
    }

    if (lower.contains('unable to validate id')) {
      return 'Unable to validate your account ID right now. Try your username instead of email, then check with your admin if the issue continues.';
    }

    if (lower.contains('bad request') ||
        lower.contains('status code of 400') ||
        lower.contains('requestoptions.validatestatus')) {
      return 'Sign-in request was rejected by the server. Try your username instead of email, and verify your account is active in the web app.';
    }

    if (lower == 'server error') {
      return 'Sign in failed. Please try again or contact your admin.';
    }

    if (_isApprovalPendingMessage(normalized)) {
      return 'Your account is pending admin approval. Please wait for approval before signing in.';
    }

    if (lower.contains('connection timeout') ||
        lower.contains('failed host lookup') ||
        lower.contains('socket')) {
      return 'Cannot reach the server. Please check your connection.';
    }

    return normalized;
  }

  bool _isApprovalPendingMessage(String message) {
    final lower = message.trim().toLowerCase();

    if (lower == 'pending' || lower == 'inactive' || lower == 'disabled') {
      return true;
    }

    if (lower.contains('pending approval') ||
        lower.contains('approval pending') ||
        lower.contains('awaiting approval') ||
        lower.contains('pending admin') ||
        lower.contains('awaiting admin') ||
        lower.contains('not approved') ||
        lower.contains('unapproved') ||
        lower.contains('approval required') ||
        (lower.contains('approved') &&
            (lower.contains('not') || lower.contains('yet'))) ||
        lower.contains('inactive') ||
        lower.contains('not active')) {
      return true;
    }

    return false;
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSignIn() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _formError = null;
    });
    ref.read(authProvider.notifier).clearError();

    if (identifier.isEmpty && password.isEmpty) {
      setState(() {
        _formError = 'Please enter your email/username and password.';
      });
      return;
    }

    if (identifier.isEmpty) {
      setState(() {
        _formError = 'Please enter your email or username.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _formError = 'Please enter your password.';
      });
      return;
    }

    await ref.read(authProvider.notifier).login(identifier, password);
  }

  Widget _buildBackLink() {
    return Semantics(
      button: true,
      label: 'Back to dashboard',
      hint: 'Navigates back to dashboard',
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(kAuthBackLinkRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kAuthMicroSpacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, size: 18, color: kAuthIconColor),
              const SizedBox(width: kAuthMicroSpacing),
              Flexible(
                child: Text(
                  'Back to dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kAuthBodyText.copyWith(color: kAuthIconColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String label, required Widget icon}) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Currently unavailable',
      child: SizedBox(
        height: kAuthSocialButtonHeight,
        child: TextButton(
          onPressed: () {
            _showInfo('$label is not available yet.');
          },
          style: TextButton.styleFrom(
            backgroundColor: kAuthCardColor,
            foregroundColor: kAuthLabelColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kAuthFieldRadius),
              side: const BorderSide(color: Color(0xFFF0F2F5)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kAuthFieldContainerHorizontalPadding,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: kAuthComfortSpacing),
              Flexible(
                child: Text(
                  label,
                  style: kAuthBodyText.copyWith(color: kAuthLabelColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: kAuthDividerColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: kAuthElementSpacing),
          child: Text('Or', style: kAuthBodyText),
        ),
        Expanded(child: Divider(color: kAuthDividerColor, thickness: 1)),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        style: kAuthLabelText,
        children: [
          TextSpan(text: label),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: kAuthRequiredAsteriskColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIndicator(
    String message, {
    bool isApprovalPending = false,
  }) {
    final backgroundColor = isApprovalPending
        ? kAuthWarningBackgroundColor
        : kAuthErrorBackgroundColor;
    final borderColor =
        isApprovalPending ? kAuthWarningBorderColor : kAuthErrorBorderColor;
    final textColor =
        isApprovalPending ? kAuthWarningTextColor : kAuthErrorTextColor;
    final iconColor =
        isApprovalPending ? kAuthWarningIconColor : kAuthErrorIconColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: kAuthFieldContainerHorizontalPadding,
        vertical: kAuthFieldContainerVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(kAuthFieldRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isApprovalPending
                  ? Icons.hourglass_top_rounded
                  : Icons.error_outline,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: kAuthCompactSpacing),
          Expanded(
            child: Text(
              message,
              style: kAuthBodyText.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final useCompactLayout = constraints.maxWidth < 420 || textScale > 1.2;

        final checkboxRow = Row(
          children: [
            Checkbox(
              value: keepMeLoggedIn,
              onChanged: (value) {
                setState(() {
                  keepMeLoggedIn = value ?? false;
                });
              },
              semanticLabel: 'Keep me logged in',
              activeColor: kAuthPrimaryButtonColor,
              checkColor: Colors.white,
              side: const BorderSide(color: kAuthInputBorderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kAuthCheckboxRadius),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(
                horizontal: -2,
                vertical: -2,
              ),
            ),
            const SizedBox(width: kAuthCompactSpacing),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    keepMeLoggedIn = !keepMeLoggedIn;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: kAuthMicroSpacing,
                  ),
                  child: Text(
                    'Keep me logged in',
                    style: kAuthBodyText.copyWith(color: kAuthLabelColor),
                  ),
                ),
              ),
            ),
          ],
        );

        final forgotButton = Semantics(
          button: true,
          label: 'Forgot password',
          hint: 'Currently unavailable',
          child: TextButton(
            onPressed: () {
              _showInfo('Forgot password is not available yet.');
            },
            style: TextButton.styleFrom(
              foregroundColor: kAuthLinkColor,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Forgot password?'),
          ),
        );

        if (useCompactLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              checkboxRow,
              const SizedBox(height: kAuthMicroSpacing),
              Align(
                alignment: Alignment.centerLeft,
                child: forgotButton,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: checkboxRow),
            forgotButton,
          ],
        );
      },
    );
  }

  Widget _buildSignUpPrompt() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: kAuthBodyText,
        ),
        Semantics(
          button: true,
          label: 'Sign Up',
          hint: 'Navigates to registration',
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const RegisterPage(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: kAuthLinkColor,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign Up',
              style: kAuthBodyText.copyWith(
                color: kAuthLinkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final serverError = authState.error;
    final indicatorMessage = _formError ??
        ((serverError != null && serverError.isNotEmpty)
            ? _friendlyAuthError(serverError)
            : null);
    final isApprovalPending =
        indicatorMessage != null && _isApprovalPendingMessage(indicatorMessage);

    return Scaffold(
      backgroundColor: kAuthBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kAuthFormMaxWidth),
            child: SingleChildScrollView(
              padding: kAuthFormScrollPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthStaggeredEntrance(
                    delay: Duration.zero,
                    child: _buildBackLink(),
                  ),
                  const SizedBox(height: kAuthContentSpacing),
                  const AuthStaggeredEntrance(
                    delay: Duration(milliseconds: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sign In', style: kAuthHeadline),
                        SizedBox(height: kAuthCompactSpacing),
                        Text(
                          'Enter your email or username and password to sign in!',
                          style: kAuthBodyText2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kAuthContentSpacing),
                  AuthStaggeredEntrance(
                    delay: const Duration(milliseconds: 80),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 460) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  label: 'Sign in with Google',
                                  icon: Text(
                                    'G',
                                    style: kAuthBodyText.copyWith(
                                      color: kAuthGoogleBrandColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: kAuthElementSpacing),
                              Expanded(
                                child: _buildSocialButton(
                                  label: 'Sign in with X',
                                  icon: Text(
                                    'X',
                                    style: kAuthBodyText.copyWith(
                                      color: kAuthLabelColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _buildSocialButton(
                              label: 'Sign in with Google',
                              icon: Text(
                                'G',
                                style: kAuthBodyText.copyWith(
                                  color: kAuthGoogleBrandColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: kAuthComfortSpacing),
                            _buildSocialButton(
                              label: 'Sign in with X',
                              icon: Text(
                                'X',
                                style: kAuthBodyText.copyWith(
                                  color: kAuthLabelColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: kAuthContentSpacing),
                  AuthStaggeredEntrance(
                    delay: const Duration(milliseconds: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrDivider(),
                        const SizedBox(height: kAuthContentSpacing),
                        _buildFieldLabel('Email or Username'),
                        AuthTextField(
                          hintText: 'Enter your email or username',
                          inputType: TextInputType.text,
                          controller: _identifierController,
                        ),
                        const SizedBox(height: kAuthMicroSpacing),
                        _buildFieldLabel('Password'),
                        AuthPasswordField(
                          isPasswordVisible: isPasswordVisible,
                          hintText: 'Enter your password',
                          controller: _passwordController,
                          onTap: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        if (indicatorMessage != null) ...[
                          const SizedBox(height: kAuthCompactSpacing),
                          _buildErrorIndicator(
                            indicatorMessage,
                            isApprovalPending: isApprovalPending,
                          ),
                        ],
                        const SizedBox(height: kAuthCompactSpacing),
                        _buildSessionControls(),
                      ],
                    ),
                  ),
                  const SizedBox(height: kAuthButtonTopSpacing),
                  AuthStaggeredEntrance(
                    delay: const Duration(milliseconds: 160),
                    child: AuthTextButton(
                      buttonName:
                          authState.isLoading ? 'Signing in...' : 'Sign In',
                      onTap: () {
                        if (authState.isLoading) {
                          return;
                        }
                        _handleSignIn();
                      },
                      bgColor: kAuthPrimaryButtonColor,
                      textColor: kAuthPrimaryButtonTextColor,
                    ),
                  ),
                  const SizedBox(height: kAuthPageBottomSpacing),
                  AuthStaggeredEntrance(
                    delay: const Duration(milliseconds: 200),
                    child: Center(
                      child: _buildSignUpPrompt(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

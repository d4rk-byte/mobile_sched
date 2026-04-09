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
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left, size: 18, color: kAuthIconColor),
            const SizedBox(width: 4),
            Text(
              'Back to dashboard',
              style: kAuthBodyText.copyWith(color: kAuthIconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String label, required Widget icon}) {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: () {
          _showInfo('$label is not available yet.');
        },
        style: TextButton.styleFrom(
          backgroundColor: kAuthCardColor,
          foregroundColor: kAuthLabelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kAuthCardBorderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
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
    );
  }

  Widget _buildOrDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: kAuthDividerColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
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
              color: Color(0xFFF04438),
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
    final backgroundColor =
        isApprovalPending ? const Color(0xFFFFFAEB) : kAuthErrorBackgroundColor;
    final borderColor =
        isApprovalPending ? const Color(0xFFFEC84B) : kAuthErrorBorderColor;
    final textColor =
        isApprovalPending ? const Color(0xFFB54708) : kAuthErrorTextColor;
    final iconColor =
        isApprovalPending ? const Color(0xFFB54708) : kAuthErrorIconColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 8),
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
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackLink(),
                  const SizedBox(height: 24),
                  const Text('Sign In', style: kAuthHeadline),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email or username and password to sign in!',
                    style: kAuthBodyText2,
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
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
                                    color: const Color(0xFF4285F4),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                color: const Color(0xFF4285F4),
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                  const SizedBox(height: 16),
                  _buildOrDivider(),
                  const SizedBox(height: 16),
                  _buildFieldLabel('Email or Username'),
                  AuthTextField(
                    hintText: 'Enter your email or username',
                    inputType: TextInputType.text,
                    controller: _identifierController,
                  ),
                  const SizedBox(height: 4),
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
                    const SizedBox(height: 8),
                    _buildErrorIndicator(
                      indicatorMessage,
                      isApprovalPending: isApprovalPending,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: keepMeLoggedIn,
                        onChanged: (value) {
                          setState(() {
                            keepMeLoggedIn = value ?? false;
                          });
                        },
                        activeColor: kAuthPrimaryButtonColor,
                        checkColor: Colors.white,
                        side: const BorderSide(color: kAuthInputBorderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keep me logged in',
                          style: kAuthBodyText.copyWith(color: kAuthLabelColor),
                        ),
                      ),
                      TextButton(
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  AuthTextButton(
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: kAuthBodyText,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: kAuthBodyText.copyWith(
                            color: kAuthLinkColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

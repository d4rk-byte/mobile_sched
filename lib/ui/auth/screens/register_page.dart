import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/widgets.dart';
import '../auth_constants.dart';
import 'signin_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool passwordVisibility = true;
  bool agreeToTerms = false;
  final _usernameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _formError;
  Timer? _usernameDebounceTimer;
  Timer? _employeeIdDebounceTimer;
  bool _usernameChecking = false;
  bool _employeeIdChecking = false;
  bool _usernameAvailable = false;
  bool _employeeIdAvailable = false;
  String? _usernameError;
  String? _employeeIdError;

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
    _usernameDebounceTimer?.cancel();
    _employeeIdDebounceTimer?.cancel();
    _usernameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyRegisterError(String message) {
    final normalized = message.trim();
    final lower = normalized.toLowerCase();

    if (lower.contains('connection timeout') ||
        lower.contains('failed host lookup') ||
        lower.contains('socket')) {
      return 'Cannot reach the server. Please check your connection.';
    }

    if (lower.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    return normalized;
  }

  String? _validateSafeUsername(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length < 3 || trimmed.length > 30) {
      return 'Username must be between 3 and 30 characters.';
    }

    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, dots, underscores, and hyphens.';
    }

    return null;
  }

  String? _validateSafeEmployeeId(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length > 20) {
      return 'Employee ID must be 20 characters or fewer.';
    }

    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(trimmed)) {
      return 'Employee ID can only contain letters, numbers, and hyphens.';
    }

    return null;
  }

  void _onUsernameChanged(String value) {
    final trimmed = value.trim();
    _usernameDebounceTimer?.cancel();

    setState(() {
      _formError = null;
      _usernameChecking = false;
      _usernameAvailable = false;
    });

    final safetyError = _validateSafeUsername(trimmed);
    if (safetyError != null) {
      setState(() {
        _usernameError = safetyError;
      });
      return;
    }

    setState(() {
      _usernameError = null;
    });

    if (trimmed.isEmpty) {
      return;
    }

    _usernameDebounceTimer = Timer(const Duration(milliseconds: 450), () {
      _checkAvailabilityField(field: 'username', value: trimmed);
    });
  }

  void _onEmployeeIdChanged(String value) {
    final trimmed = value.trim();
    _employeeIdDebounceTimer?.cancel();

    setState(() {
      _formError = null;
      _employeeIdChecking = false;
      _employeeIdAvailable = false;
    });

    final safetyError = _validateSafeEmployeeId(trimmed);
    if (safetyError != null) {
      setState(() {
        _employeeIdError = safetyError;
      });
      return;
    }

    setState(() {
      _employeeIdError = null;
    });

    if (trimmed.isEmpty) {
      return;
    }

    _employeeIdDebounceTimer = Timer(const Duration(milliseconds: 450), () {
      _checkAvailabilityField(field: 'employeeId', value: trimmed);
    });
  }

  Future<void> _checkAvailabilityField({
    required String field,
    required String value,
  }) async {
    final isUsernameField = field == 'username';

    if (isUsernameField) {
      setState(() {
        _usernameChecking = true;
      });
    } else {
      setState(() {
        _employeeIdChecking = true;
      });
    }

    try {
      final result =
          await ref.read(apiServiceProvider).checkRegisterAvailability(
                field: field,
                value: value,
              );

      if (!mounted) {
        return;
      }

      final currentValue = isUsernameField
          ? _usernameController.text.trim()
          : _employeeIdController.text.trim();
      if (currentValue != value) {
        return;
      }

      final available = result['available'] == true;
      final message = (result['message'] as String?)?.trim();

      setState(() {
        if (isUsernameField) {
          _usernameAvailable = available;
          _usernameError = available
              ? null
              : (message?.isNotEmpty == true
                  ? message
                  : 'Username is already taken.');
        } else {
          _employeeIdAvailable = available;
          _employeeIdError = available
              ? null
              : (message?.isNotEmpty == true
                  ? message
                  : 'Employee ID is already in use.');
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      final currentValue = isUsernameField
          ? _usernameController.text.trim()
          : _employeeIdController.text.trim();
      if (currentValue != value) {
        return;
      }

      setState(() {
        if (isUsernameField) {
          _usernameAvailable = false;
          _usernameError = 'Unable to validate username right now.';
        } else {
          _employeeIdAvailable = false;
          _employeeIdError = 'Unable to validate employee ID right now.';
        }
      });
    } finally {
      if (mounted) {
        final currentValue = isUsernameField
            ? _usernameController.text.trim()
            : _employeeIdController.text.trim();
        if (currentValue == value) {
          setState(() {
            if (isUsernameField) {
              _usernameChecking = false;
            } else {
              _employeeIdChecking = false;
            }
          });
        }
      }
    }
  }

  Future<bool> _validateAvailabilityBeforeSubmit({
    required String username,
    required String employeeId,
  }) async {
    if (_usernameChecking || _employeeIdChecking) {
      setState(() {
        _formError =
            'Please wait for username and employee ID validation to finish.';
      });
      return false;
    }

    setState(() {
      _usernameChecking = true;
      _employeeIdChecking = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final results = await Future.wait([
        api.checkRegisterAvailability(field: 'username', value: username),
        api.checkRegisterAvailability(field: 'employeeId', value: employeeId),
      ]);

      if (!mounted) {
        return false;
      }

      final usernameResult = results[0];
      final employeeResult = results[1];

      final usernameAvailable = usernameResult['available'] == true;
      final employeeIdAvailable = employeeResult['available'] == true;

      final usernameMessage = (usernameResult['message'] as String?)?.trim();
      final employeeMessage = (employeeResult['message'] as String?)?.trim();

      setState(() {
        _usernameAvailable = usernameAvailable;
        _employeeIdAvailable = employeeIdAvailable;
        _usernameError = usernameAvailable
            ? null
            : (usernameMessage?.isNotEmpty == true
                ? usernameMessage
                : 'Username is already taken.');
        _employeeIdError = employeeIdAvailable
            ? null
            : (employeeMessage?.isNotEmpty == true
                ? employeeMessage
                : 'Employee ID is already in use.');
        if (!usernameAvailable || !employeeIdAvailable) {
          _formError = 'Please fix username and employee ID before signing up.';
        }
      });

      return usernameAvailable && employeeIdAvailable;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _usernameAvailable = false;
        _employeeIdAvailable = false;
        _usernameError = 'Unable to validate username right now.';
        _employeeIdError = 'Unable to validate employee ID right now.';
        _formError =
            'Unable to validate username or employee ID right now. Please try again.';
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _usernameChecking = false;
          _employeeIdChecking = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final employeeId = _employeeIdController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _formError = null;
    });
    ref.read(authProvider.notifier).clearError();

    if (username.isEmpty ||
        employeeId.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setState(() {
        _formError = 'Please fill up all required fields.';
      });
      return;
    }

    final usernameSafetyError = _validateSafeUsername(username);
    final employeeIdSafetyError = _validateSafeEmployeeId(employeeId);

    if (usernameSafetyError != null || employeeIdSafetyError != null) {
      setState(() {
        _usernameAvailable = false;
        _employeeIdAvailable = false;
        _usernameError = usernameSafetyError;
        _employeeIdError = employeeIdSafetyError;
      });
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      setState(() {
        _formError = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _formError = 'Password must be at least 8 characters.';
      });
      return;
    }

    if (!agreeToTerms) {
      setState(() {
        _formError = 'Please agree to the Terms and Conditions.';
      });
      return;
    }

    final isAvailabilityValid = await _validateAvailabilityBeforeSubmit(
      username: username,
      employeeId: employeeId,
    );
    if (!isAvailabilityValid) {
      return;
    }

    final message = await ref.read(authProvider.notifier).register(
          username: username,
          employeeId: employeeId,
          email: email,
          password: password,
        );

    if (!mounted) {
      return;
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: kAuthFieldAvailableTextColor,
        ),
      );
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const SignInPage()),
      );
    }
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label is not available yet.')),
            );
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

  Widget _buildErrorIndicator(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: kAuthFieldContainerHorizontalPadding,
        vertical: kAuthFieldContainerVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: kAuthErrorBackgroundColor,
        borderRadius: BorderRadius.circular(kAuthFieldRadius),
        border: Border.all(color: kAuthErrorBorderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline,
              size: 18,
              color: kAuthErrorIconColor,
            ),
          ),
          const SizedBox(width: kAuthCompactSpacing),
          Expanded(
            child: Text(
              message,
              style: kAuthBodyText.copyWith(color: kAuthErrorTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityField({
    required String label,
    required String hint,
    required TextInputType inputType,
    required TextEditingController controller,
    required bool checking,
    required bool available,
    required String? errorText,
    required void Function(String value) onChanged,
    required String checkingText,
    required String availableText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    final borderColor = hasError
        ? kAuthErrorBorderColor
        : (available ? kAuthFieldAvailableBorderColor : kAuthInputBorderColor);
    final focusedBorderColor = hasError
        ? kAuthErrorStrongColor
        : (available
            ? kAuthFieldAvailableFocusedColor
            : kAuthInputFocusedBorderColor);

    Widget? suffixIcon;
    if (checking) {
      suffixIcon = const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: kAuthInputHintColor,
          ),
        ),
      );
    } else if (available && !hasError) {
      suffixIcon = const Icon(
        Icons.check_circle,
        size: 18,
        color: kAuthFieldAvailableFocusedColor,
      );
    }

    String? helperText;
    Color helperColor = kAuthBodyText.color ?? kAuthIconColor;

    if (hasError) {
      helperText = errorText;
      helperColor = kAuthErrorStrongColor;
    } else if (checking) {
      helperText = checkingText;
      helperColor = kAuthIconColor;
    } else if (available) {
      helperText = availableText;
      helperColor = kAuthFieldAvailableTextColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: kAuthTightSpacing),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: inputType,
          textInputAction: TextInputAction.next,
          style: kAuthBodyText.copyWith(color: kAuthLabelColor),
          cursorColor: kAuthPrimaryButtonColor,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: kAuthSectionSpacing,
              vertical: kAuthElementSpacing,
            ),
            hintText: hint,
            hintStyle: kAuthBodyText.copyWith(color: kAuthInputHintColor),
            filled: true,
            fillColor: kAuthTextFieldFill,
            suffixIcon: suffixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: kAuthElementSpacing),
                    child: suffixIcon,
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 24),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(kAuthFieldRadius),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: focusedBorderColor, width: 1.2),
              borderRadius: BorderRadius.circular(kAuthFieldRadius),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: kAuthTightSpacing),
          Text(
            helperText,
            style: kAuthBodyText.copyWith(
              color: helperColor,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required String hint,
    required TextInputType inputType,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        AuthTextField(
          hintText: hint,
          inputType: inputType,
          controller: controller,
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: kAuthBodyText,
        ),
        Semantics(
          button: true,
          label: 'Sign In',
          hint: 'Navigates to sign in',
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (context) => const SignInPage(),
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
              'Sign In',
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
            ? _friendlyRegisterError(serverError)
            : null);

    final canSubmit = !authState.isLoading &&
        !_usernameChecking &&
        !_employeeIdChecking &&
        agreeToTerms;

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
                        Text('Sign Up', style: kAuthHeadline),
                        SizedBox(height: kAuthCompactSpacing),
                        Text(
                          'Enter your account details to create account!',
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
                                  label: 'Sign up with Google',
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
                                  label: 'Sign up with X',
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
                              label: 'Sign up with Google',
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
                              label: 'Sign up with X',
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
                  const SizedBox(height: kAuthSectionSpacing),
                  AuthStaggeredEntrance(
                    delay: const Duration(milliseconds: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrDivider(),
                        const SizedBox(height: kAuthSectionSpacing),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 520) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildAvailabilityField(
                                      label: 'Username',
                                      hint: 'Enter your username',
                                      inputType: TextInputType.name,
                                      controller: _usernameController,
                                      checking: _usernameChecking,
                                      available: _usernameAvailable,
                                      errorText: _usernameError,
                                      onChanged: _onUsernameChanged,
                                      checkingText:
                                          'Checking username availability...',
                                      availableText: 'Username is available.',
                                    ),
                                  ),
                                  const SizedBox(width: kAuthSectionSpacing),
                                  Expanded(
                                    child: _buildAvailabilityField(
                                      label: 'Employee ID',
                                      hint: 'Enter your employee ID',
                                      inputType: TextInputType.text,
                                      controller: _employeeIdController,
                                      checking: _employeeIdChecking,
                                      available: _employeeIdAvailable,
                                      errorText: _employeeIdError,
                                      onChanged: _onEmployeeIdChanged,
                                      checkingText:
                                          'Checking employee ID availability...',
                                      availableText:
                                          'Employee ID is available.',
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _buildAvailabilityField(
                                  label: 'Username',
                                  hint: 'Enter your username',
                                  inputType: TextInputType.name,
                                  controller: _usernameController,
                                  checking: _usernameChecking,
                                  available: _usernameAvailable,
                                  errorText: _usernameError,
                                  onChanged: _onUsernameChanged,
                                  checkingText:
                                      'Checking username availability...',
                                  availableText: 'Username is available.',
                                ),
                                const SizedBox(height: kAuthTightSpacing),
                                _buildAvailabilityField(
                                  label: 'Employee ID',
                                  hint: 'Enter your employee ID',
                                  inputType: TextInputType.text,
                                  controller: _employeeIdController,
                                  checking: _employeeIdChecking,
                                  available: _employeeIdAvailable,
                                  errorText: _employeeIdError,
                                  onChanged: _onEmployeeIdChanged,
                                  checkingText:
                                      'Checking employee ID availability...',
                                  availableText: 'Employee ID is available.',
                                ),
                              ],
                            );
                          },
                        ),
                        _buildLabeledTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          inputType: TextInputType.emailAddress,
                          controller: _emailController,
                        ),
                        _buildFieldLabel('Password'),
                        AuthPasswordField(
                          isPasswordVisible: passwordVisibility,
                          hintText: 'Enter your password',
                          controller: _passwordController,
                          onTap: () {
                            setState(() {
                              passwordVisibility = !passwordVisibility;
                            });
                          },
                        ),
                        if (indicatorMessage != null) ...[
                          const SizedBox(height: kAuthCompactSpacing),
                          _buildErrorIndicator(indicatorMessage),
                        ],
                        const SizedBox(height: kAuthTightSpacing),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  agreeToTerms = value ?? false;
                                });
                              },
                              semanticLabel:
                                  'Agree to the Terms and Conditions and Privacy Policy',
                              activeColor: kAuthPrimaryButtonColor,
                              checkColor: Colors.white,
                              side: const BorderSide(
                                  color: kAuthInputBorderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(kAuthCheckboxRadius),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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
                                    agreeToTerms = !agreeToTerms;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: kAuthMicroSpacing,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: kAuthBodyText,
                                      children: [
                                        const TextSpan(
                                          text:
                                              'By creating an account you agree to the ',
                                        ),
                                        TextSpan(
                                          text: 'Terms and Conditions',
                                          style: kAuthBodyText.copyWith(
                                            color: kAuthLabelColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const TextSpan(text: ', and our '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: kAuthBodyText.copyWith(
                                            color: kAuthLabelColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kAuthButtonTopSpacing),
                  AuthStaggeredEntrance(
                    delay: const Duration(milliseconds: 170),
                    child: AuthTextButton(
                      buttonName: authState.isLoading
                          ? 'Creating account...'
                          : 'Sign Up',
                      onTap: () {
                        if (!canSubmit) {
                          if (_usernameChecking || _employeeIdChecking) {
                            setState(() {
                              _formError =
                                  'Please wait for username and employee ID validation to finish.';
                            });
                          } else if (!agreeToTerms) {
                            setState(() {
                              _formError =
                                  'Please agree to the Terms and Conditions.';
                            });
                          }
                          return;
                        }
                        _handleRegister();
                      },
                      bgColor: canSubmit
                          ? kAuthPrimaryButtonColor
                          : kAuthPrimaryDisabledColor,
                      textColor: kAuthPrimaryButtonTextColor,
                    ),
                  ),
                  const SizedBox(height: kAuthPageBottomSpacing),
                  AuthStaggeredEntrance(
                    delay: const Duration(milliseconds: 210),
                    child: Center(
                      child: _buildSignInPrompt(),
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

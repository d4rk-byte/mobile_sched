// lib/screens/login_screen.dart
// Legacy screen — replaced by SignInPage. This file is kept only as a
// compatibility shim; nothing in the active codebase references it.

import 'package:flutter/material.dart';
import '../ui/auth/screens/signin_page.dart';

/// Compatibility redirect to [SignInPage].
///
/// Use [SignInPage] directly for all new navigation.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignInPage();
  }
}


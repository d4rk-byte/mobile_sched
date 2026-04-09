import 'package:flutter/material.dart';
import '../auth_constants.dart';

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    super.key,
    required this.isPasswordVisible,
    required this.onTap,
    this.hintText = 'Enter your password',
    this.controller,
  });

  final bool isPasswordVisible;
  final VoidCallback onTap;
  final String hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        style: kAuthBodyText.copyWith(color: const Color(0xFF1D2939)),
        cursorColor: kAuthPrimaryButtonColor,
        obscureText: isPasswordVisible,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          suffixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: onTap,
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: kAuthIconColor,
              ),
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hintText,
          hintStyle: kAuthBodyText.copyWith(color: kAuthInputHintColor),
          filled: true,
          fillColor: kAuthTextFieldFill,
          enabledBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: kAuthInputBorderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: kAuthInputFocusedBorderColor,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

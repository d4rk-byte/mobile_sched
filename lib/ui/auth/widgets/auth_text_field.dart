import 'package:flutter/material.dart';
import '../auth_constants.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hintText,
    required this.inputType,
    this.controller,
  });

  final String hintText;
  final TextInputType inputType;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        style: kAuthBodyText.copyWith(color: const Color(0xFF1D2939)),
        cursorColor: kAuthPrimaryButtonColor,
        keyboardType: inputType,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
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

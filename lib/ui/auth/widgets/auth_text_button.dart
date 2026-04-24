import 'package:flutter/material.dart';
import '../auth_constants.dart';

class AuthTextButton extends StatelessWidget {
  const AuthTextButton({
    super.key,
    required this.buttonName,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
  });

  final String buttonName;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final overlayColor = bgColor == Colors.transparent
        ? kAuthPrimaryButtonColor.withValues(alpha: 0.10)
        : kAuthPrimaryButtonColor.withValues(alpha: 0.18);

    return Container(
      height: kAuthControlHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(kAuthFieldRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextButton(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => overlayColor,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kAuthFieldRadius),
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          buttonName,
          style: kAuthButtonText.copyWith(color: textColor),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/configs/theme.dart';

// Colors
const kAuthBackgroundColor = AppColors.backgroundColor;
const kAuthTextFieldFill = AppColors.whiteColor;
const kAuthCardColor = AppColors.cardSurface;
const kAuthCardBorderColor = AppColors.cardBorder;
const kAuthInputBorderColor = AppColors.cardBorder;
const kAuthInputFocusedBorderColor = AppColors.cardPrimaryEnd;
const kAuthInputHintColor = AppColors.textSecondary;
const kAuthPrimaryButtonColor = AppColors.cardPrimaryEnd;
const kAuthPrimaryButtonTextColor = AppColors.whiteColor;
const kAuthLinkColor = AppColors.cardPrimaryEnd;
const kAuthIconColor = AppColors.textSecondary;
const kAuthLabelColor = AppColors.textPrimary;
const kAuthDividerColor = AppColors.divider;
const kAuthErrorBackgroundColor = Color(0xFFFEF3F2);
const kAuthErrorBorderColor = Color(0xFFFDA29B);
const kAuthErrorTextColor = Color(0xFFB42318);
const kAuthErrorIconColor = Color(0xFFD92D20);
const kAuthErrorStrongColor = Color(0xFFF04438);
const kAuthWarningBackgroundColor = Color(0xFFFFFAEB);
const kAuthWarningBorderColor = Color(0xFFFEC84B);
const kAuthWarningTextColor = Color(0xFFB54708);
const kAuthWarningIconColor = Color(0xFFB54708);
const kAuthRequiredAsteriskColor = AppColors.error;
const kAuthGoogleBrandColor = Color(0xFF4285F4);
const kAuthFieldAvailableBorderColor = Color(0xFF32D583);
const kAuthFieldAvailableFocusedColor = Color(0xFF12B76A);
const kAuthFieldAvailableTextColor = Color(0xFF039855);
const kAuthPrimaryDisabledColor = AppColors.primaryLight;

// Sizing
const kAuthPageHorizontalPadding = AppSpacing.xl;
const kAuthPageBottomSpacing = AppSpacing.xl;
const kAuthSectionSpacing = AppSpacing.lg;
const kAuthElementSpacing = AppSpacing.md;
const kAuthCompactSpacing = AppSpacing.sm;
const kAuthMicroSpacing = AppSpacing.xs;
const kAuthTightSpacing = 6.0;
const kAuthComfortSpacing = 10.0;
const kAuthContentSpacing = AppSpacing.xxl;
const kAuthButtonTopSpacing = 18.0;
const kAuthControlHeight = 54.0;
const kAuthSocialButtonHeight = 48.0;
const kAuthFormMaxWidth = 640.0;
const kAuthCardRadius = AppRadius.lg;
const kAuthFieldRadius = AppRadius.md;
const kAuthBackLinkRadius = AppSpacing.sm;
const kAuthCheckboxRadius = 4.0;
const kAuthFieldContainerHorizontalPadding = 14.0;
const kAuthFieldContainerVerticalPadding = 10.0;
const kAuthFormScrollPadding = EdgeInsets.fromLTRB(
  AppSpacing.xxl,
  AppSpacing.lg,
  AppSpacing.xxl,
  AppSpacing.xxl,
);

// TextStyles
const kAuthHeadline = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 32,
  height: 1.15,
  letterSpacing: -0.6,
  fontWeight: FontWeight.w700,
);

const kAuthBodyText = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 14,
  height: 1.45,
);

const kAuthButtonText = TextStyle(
  fontFamily: 'Outfit',
  color: kAuthPrimaryButtonTextColor,
  fontSize: 15,
  fontWeight: FontWeight.w600,
);

const kAuthBodyText2 = TextStyle(
  fontSize: 16,
  height: 1.4,
  fontWeight: FontWeight.w400,
  color: AppColors.textSecondary,
);

const kAuthLabelText = TextStyle(
  fontFamily: 'Outfit',
  color: kAuthLabelColor,
  fontSize: 14,
  height: 1.25,
  fontWeight: FontWeight.w500,
);

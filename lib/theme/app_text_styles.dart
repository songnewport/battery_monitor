import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const pageTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.2,
  );

  static const headline = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
  );

  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  static const cardLabel = TextStyle(
    fontSize: 13,
    letterSpacing: 1.2,
    color: AppColors.secondaryText,
    fontWeight: FontWeight.w600,
  );

  static const cardValue = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const unit = TextStyle(
    fontSize: 16,
    color: AppColors.secondaryText,
    fontWeight: FontWeight.w500,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.secondaryText,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.tertiaryText,
    fontWeight: FontWeight.w500,
  );

  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );
}

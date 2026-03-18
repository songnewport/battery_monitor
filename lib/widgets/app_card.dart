import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final bool gradient;
  final EdgeInsetsGeometry padding;
  final Border? border;
  final double radius;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.gradient = false,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.border,
    this.radius = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: gradient ? null : (color ?? AppColors.panel),
        gradient: gradient
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.cardTop, AppColors.cardBottom],
              )
            : null,
        border: border,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

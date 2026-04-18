import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;

  const GradientContainer({
    super.key,
    required this.child,
    this.gradient,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 0),
      ),
      child: child,
    );
  }
}

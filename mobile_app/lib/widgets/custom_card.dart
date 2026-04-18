import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.shadow,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.medium),
        boxShadow: shadow ?? AppShadows.card,
        border: border,
      ),
      child: child,
    );
  }
}

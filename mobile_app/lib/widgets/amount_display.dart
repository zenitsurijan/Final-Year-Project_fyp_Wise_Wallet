import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool isExpense;
  final bool animate;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.style,
    this.isExpense = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          CurrencyUtils.format(amount),
          style: style ?? TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

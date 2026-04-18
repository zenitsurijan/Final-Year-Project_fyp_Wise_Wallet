import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.small,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget listTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          const LoadingShimmer(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingShimmer(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const LoadingShimmer(width: 100, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const LoadingShimmer(width: 60, height: 16),
        ],
      ),
    );
  }

  static Widget card() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: LoadingShimmer(width: double.infinity, height: 150, borderRadius: 16),
    );
  }
}

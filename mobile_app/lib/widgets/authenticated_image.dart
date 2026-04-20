import 'package:flutter/material.dart';

class AuthenticatedImage extends StatelessWidget {
  final String imageId;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AuthenticatedImage({
    super.key,
    required this.imageId,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Cloudinary URL directly use गर्छ
    final String imageUrl = imageId.startsWith('http')
        ? imageId
        : 'https://res.cloudinary.com/de4fpkglc/image/upload/$imageId';

    final image = Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          height: height ?? 200,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Container(
          height: height ?? 200,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
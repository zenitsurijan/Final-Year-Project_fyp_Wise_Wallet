import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthenticatedImage extends StatefulWidget {
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
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageId != widget.imageId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getImageWithAuth(widget.imageId);
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _imageData = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load image (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            height: widget.height ?? 200,
            width: widget.width ?? double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    if (_error != null || _imageData == null) {
      return widget.errorWidget ??
          Container(
            height: widget.height ?? 200,
            width: widget.width ?? double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(_error ?? 'Failed to load image',
                      style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
    }

    final image = Image.memory(
      _imageData!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

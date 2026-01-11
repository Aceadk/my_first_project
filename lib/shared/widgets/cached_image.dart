import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../design_system/tokens/colors.dart';

/// A reusable cached network image with placeholder and error handling.
///
/// Uses [CachedNetworkImage] for efficient caching and lazy loading.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ?? const _DefaultPlaceholder(),
      errorWidget: (context, url, error) =>
          errorWidget ?? const _DefaultErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Cached image optimized for circular avatars.
class CachedCircleAvatar extends StatelessWidget {
  const CachedCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.placeholder,
    this.backgroundColor,
  });

  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? DsColors.skeletonLight,
        child: placeholder ??
            Icon(
              Icons.person,
              color: DsColors.textMutedLight,
              size: radius,
            ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? DsColors.skeletonLight,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? DsColors.skeletonLight,
        child: SizedBox(
          width: radius,
          height: radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? DsColors.skeletonLight,
        child: placeholder ??
            Icon(
              Icons.person,
              color: DsColors.textMutedLight,
              size: radius,
            ),
      ),
    );
  }
}

/// Default placeholder shown while image is loading.
class _DefaultPlaceholder extends StatelessWidget {
  const _DefaultPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DsColors.skeletonLight,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DsColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Default error widget shown when image fails to load.
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DsColors.skeletonLight,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: DsColors.textMutedLight,
          size: 32,
        ),
      ),
    );
  }
}

/// Profile-specific placeholder for larger images.
class ProfileImagePlaceholder extends StatelessWidget {
  const ProfileImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DsColors.primary.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 80,
          color: DsColors.primary,
        ),
      ),
    );
  }
}

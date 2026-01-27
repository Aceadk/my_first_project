import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// A profile avatar widget with optional online indicator and verification badge.
class CrushAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showOnlineIndicator;
  final bool isOnline;
  final bool showVerifiedBadge;
  final bool isVerified;
  final VoidCallback? onTap;

  const CrushAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.showVerifiedBadge = false,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build semantic label
    final List<String> semanticParts = [];
    if (name != null && name!.isNotEmpty) {
      semanticParts.add('Avatar of $name');
    } else {
      semanticParts.add('User avatar');
    }
    if (showOnlineIndicator) {
      semanticParts.add(isOnline ? 'Online' : 'Offline');
    }
    if (showVerifiedBadge && isVerified) {
      semanticParts.add('Verified');
    }

    return Semantics(
      image: true,
      label: semanticParts.join(', '),
      button: onTap != null,
      hint: onTap != null ? 'Double tap to view profile' : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? DsColors.surfaceDark : DsColors.inputFillLight,
                  border: Border.all(
                    color: isDark ? DsColors.borderDark : DsColors.borderLight,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(initials, isDark),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _buildLoadingPlaceholder(isDark);
                          },
                        )
                      : _buildPlaceholder(initials, isDark),
                ),
              ),
              if (showOnlineIndicator)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _OnlineIndicator(
                    isOnline: isOnline,
                    size: size * 0.28,
                  ),
                ),
              if (showVerifiedBadge && isVerified)
                Positioned(
                  right: -2,
                  top: -2,
                  child: _VerifiedBadge(size: size * 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String initials, bool isDark) {
    return Container(
      color: DsColors.primary.withAlpha((0.1 * 255).round()),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                  color: DsColors.primary,
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.5,
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(bool isDark) {
    return Container(
      color: isDark ? DsColors.surfaceDark : DsColors.inputFillLight,
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DsColors.primary.withAlpha((0.5 * 255).round()),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const _OnlineIndicator({
    required this.isOnline,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? DsColors.onlineIndicator : DsColors.offlineIndicator,
        border: Border.all(
          color: isDark ? DsColors.backgroundDark : Colors.white,
          width: size * 0.15,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final double size;

  const _VerifiedBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.lightBlueAccent,
      ),
      child: Icon(
        Icons.check,
        size: size * 0.65,
        color: Colors.white,
      ),
    );
  }
}

/// A row of stacked avatars for showing multiple people (e.g., mutual friends).
class CrushAvatarStack extends StatelessWidget {
  final List<String?> imageUrls;
  final double avatarSize;
  final double overlap;
  final int maxVisible;

  const CrushAvatarStack({
    super.key,
    required this.imageUrls,
    this.avatarSize = 32,
    this.overlap = 0.3,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final visible = imageUrls.take(maxVisible).toList();
    final remaining = imageUrls.length - maxVisible;
    final effectiveOverlap = avatarSize * overlap;

    return SizedBox(
      height: avatarSize,
      width: avatarSize + (visible.length - 1) * (avatarSize - effectiveOverlap) +
          (remaining > 0 ? avatarSize - effectiveOverlap : 0),
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (avatarSize - effectiveOverlap),
              child: CrushAvatar(
                imageUrl: visible[i],
                size: avatarSize,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visible.length * (avatarSize - effectiveOverlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DsColors.primary,
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: avatarSize * 0.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/models/profile.dart';
import '../screens/profile_media_screen.dart';
import 'cached_network_image.dart';

class SwipeCard extends StatelessWidget {
  final Profile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.displayPhotoUrl;
    final displayName =
        profile.name.trim().isEmpty ? 'Someone new' : profile.name.trim();
    final ageText = profile.age > 0 ? '${profile.age}' : 'N/A';
    final bio = profile.bio.trim().isEmpty
        ? 'This member has not added a bio yet.'
        : profile.bio;
    final city = profile.city.trim();
    final country = profile.country.trim();
    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(city.isNotEmpty && country.isNotEmpty ? ', ' : '');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileMediaScreen(profile: profile),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: _placeholder(),
                errorWidget: _placeholder(),
              )
            else
              _placeholder(),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _VerificationPill(isVerified: profile.isVerified),
            ),
            Positioned(
              left: 16,
              bottom: 24,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayName, $ageText',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.isEmpty ? 'Location unavailable' : location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.white54,
          size: 64,
        ),
      ),
    );
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? Colors.lightBlueAccent : Colors.orangeAccent;
    final text = isVerified ? 'Verified' : 'Not verified';
    final icon = isVerified ? Icons.verified : Icons.privacy_tip_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.18 * 255).round()),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

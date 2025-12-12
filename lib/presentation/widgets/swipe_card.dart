import 'package:flutter/material.dart';
import '../../data/models/profile.dart';
import '../screens/profile_media_screen.dart';

class SwipeCard extends StatelessWidget {
  final Profile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;
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
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
              )
            else
              Container(color: Colors.grey.shade800),
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
              left: 16,
              bottom: 24,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Text(
                      '${profile.name}, ${profile.age}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.lightBlueAccent),
                    ],
                  ],
                ),
                  const SizedBox(height: 4),
                  Text(
                    profile.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.city}, ${profile.country}',
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
}

import 'package:flutter/material.dart';
import '../../data/models/profile.dart';

class SwipeCard extends StatelessWidget {
  final Profile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;
    return Card(
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
                Text(
                  '${profile.name}, ${profile.age}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }
}

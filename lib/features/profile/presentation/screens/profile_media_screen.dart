import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';

class ProfileMediaArgs {
  final Profile profile;

  const ProfileMediaArgs({required this.profile});
}

class ProfileMediaScreen extends StatefulWidget {
  const ProfileMediaScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<ProfileMediaScreen> createState() => _ProfileMediaScreenState();
}

class _ProfileMediaScreenState extends State<ProfileMediaScreen>
    with SingleTickerProviderStateMixin {
  late final List<String> _validVideoUrls;
  late final List<VideoPlayerController> _videoControllers;
  late final List<Future<void>> _videoInits;

  @override
  void initState() {
    super.initState();
    _validVideoUrls = widget.profile.videoUrls.where((url) {
      final uri = Uri.tryParse(url);
      return uri != null &&
          uri.hasScheme &&
          (uri.isScheme('http') || uri.isScheme('https'));
    }).toList();
    _videoControllers = _validVideoUrls
        .map(
          (url) => VideoPlayerController.networkUrl(Uri.parse(url)),
        )
        .toList();
    _videoInits = _videoControllers.map((c) => c.initialize()).toList();
  }

  @override
  void dispose() {
    for (final c in _videoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.profile.photoUrls;
    final videos = _validVideoUrls;
    final displayName = widget.profile.publicDisplayNameOr('This member');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$displayName's media"),
              if (widget.profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: DsColors.info),
              ],
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Photos'),
              Tab(text: 'Videos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (photos.isEmpty)
              const Center(child: Text('No photos yet'))
            else
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final url = photos[index];
                        return InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            errorWidget: const Center(
                              child: Text('Photo unavailable'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      '${photos.length} photo${photos.length == 1 ? '' : 's'}'),
                  const SizedBox(height: 12),
                ],
              ),
            if (videos.isEmpty)
              const Center(child: Text('No videos yet'))
            else
              ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: videos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final controller = _videoControllers[index];
                  final init = _videoInits[index];
                  return FutureBuilder<void>(
                    future: init,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          height: 200,
                          color: DsColors.ink900.withValues(alpha: 0.12),
                          child: const Center(
                            child: Text('Could not load video'),
                          ),
                        );
                      }
                      return _VideoPlayerTile(controller: controller);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerTile extends StatefulWidget {
  const _VideoPlayerTile({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoPlayerTile> createState() => _VideoPlayerTileState();
}

class _VideoPlayerTileState extends State<_VideoPlayerTile> {
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _playing = widget.controller.value.isPlaying;
    widget.controller.addListener(_onTick);
  }

  void _onTick() {
    final next = widget.controller.value.isPlaying;
    if (next != _playing) {
      setState(() => _playing = next);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: widget.controller.value.aspectRatio == 0
              ? 16 / 9
              : widget.controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(widget.controller),
              IconButton.filled(
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (_playing) {
                    widget.controller.pause();
                  } else {
                    widget.controller.play();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/profile.dart';

class ProfileMediaScreen extends StatefulWidget {
  const ProfileMediaScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<ProfileMediaScreen> createState() => _ProfileMediaScreenState();
}

class _ProfileMediaScreenState extends State<ProfileMediaScreen>
    with SingleTickerProviderStateMixin {
  late final List<VideoPlayerController> _videoControllers;
  late final List<Future<void>> _videoInits;

  @override
  void initState() {
    super.initState();
    _videoControllers = widget.profile.videoUrls
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
    final videos = widget.profile.videoUrls;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.profile.name}\'s media'),
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
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${photos.length} photo${photos.length == 1 ? '' : 's'}'),
                  const SizedBox(height: 12),
                ],
              ),
            if (videos.isEmpty)
              const Center(child: Text('No videos yet'))
            else
              ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                          color: Colors.black12,
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

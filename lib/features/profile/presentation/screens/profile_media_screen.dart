import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

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
        .map((url) => VideoPlayerController.networkUrl(Uri.parse(url)))
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
    final photos = widget.profile.displayOrderedPhotoUrls;
    final videos = _validVideoUrls;
    final displayName = widget.profile.publicDisplayNameOr('This member');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Text(
                  "$displayName's media",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth > DsBreakpoints.contentMaxLargeDesktop
                ? DsBreakpoints.contentMaxLargeDesktop
                : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: TabBarView(
                  children: [
                    if (photos.isEmpty)
                      Center(
                        child: Text(AppLocalizations.of(context).noPhotosYet),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, photoConstraints) {
                          final columns = _photoColumnsForWidth(
                            photoConstraints.maxWidth,
                          );
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: photos.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.78,
                                ),
                            itemBuilder: (context, index) {
                              final url = photos[index];
                              return _PhotoGridTile(
                                imageUrl: url,
                                onTap: () => _showPhotoPreview(
                                  context,
                                  url,
                                  displayName,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    if (videos.isEmpty)
                      Center(
                        child: Text(AppLocalizations.of(context).noVideosYet),
                      )
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
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return Container(
                                  height: 200,
                                  color: DsColors.ink900.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).couldNotLoadVideo,
                                    ),
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
          },
        ),
      ),
    );
  }

  int _photoColumnsForWidth(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    return 2;
  }

  void _showPhotoPreview(
    BuildContext context,
    String imageUrl,
    String displayName,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$displayName's photo",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 420,
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: Center(
                      child: Text(
                        AppLocalizations.of(context).photoUnavailable,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoGridTile extends StatelessWidget {
  const _PhotoGridTile({required this.imageUrl, required this.onTap});

  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            errorWidget: Center(
              child: Text(AppLocalizations.of(context).photoUnavailable),
            ),
          ),
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

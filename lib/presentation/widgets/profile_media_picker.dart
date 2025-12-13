import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/profile_media_limits.dart';

class ProfileMediaSelection {
  final List<String> photos;
  final List<String> videos;

  const ProfileMediaSelection({
    required this.photos,
    required this.videos,
  });
}

class ProfileMediaPicker extends StatefulWidget {
  const ProfileMediaPicker({
    super.key,
    required this.initialPhotos,
    required this.initialVideos,
    required this.onChanged,
    this.enabled = true,
    this.onError,
  });

  final List<String> initialPhotos;
  final List<String> initialVideos;
  final bool enabled;
  final ValueChanged<ProfileMediaSelection> onChanged;
  final ValueChanged<String>? onError;

  @override
  State<ProfileMediaPicker> createState() => _ProfileMediaPickerState();
}

class _ProfileMediaPickerState extends State<ProfileMediaPicker> {
  late List<String> _photos;
  late List<String> _videos;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.initialPhotos);
    _videos = List.of(widget.initialVideos);
  }

  @override
  void didUpdateWidget(covariant ProfileMediaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhotos != widget.initialPhotos ||
        oldWidget.initialVideos != widget.initialVideos) {
      setState(() {
        _photos = List.of(widget.initialPhotos);
        _videos = List.of(widget.initialVideos);
      });
    }
  }

  void _notify() {
    widget.onChanged(
      ProfileMediaSelection(photos: List.of(_photos), videos: List.of(_videos)),
    );
  }

  void _showError(String message) {
    if (widget.onError != null) {
      widget.onError!(message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _addPhotos() async {
    if (!widget.enabled) return;
    final remaining = ProfileMediaLimits.maxPhotos - _photos.length;
    if (remaining <= 0) {
      _showError('You can add up to ${ProfileMediaLimits.maxPhotos} photos.');
      return;
    }
    final files = await _picker.pickMultiImage(
      imageQuality: 72,
      maxWidth: 1440,
    );
    if (files.isEmpty) return;

    final selected = files.take(remaining).toList();
    setState(() {
      _photos.addAll(selected.map((x) => x.path));
    });
    _notify();

    if (files.length > selected.length) {
      _showError('Only $remaining more photo slot${remaining == 1 ? '' : 's'} available.');
    }
  }

  Future<void> _addVideo() async {
    if (!widget.enabled) return;
    final remaining = ProfileMediaLimits.maxVideos - _videos.length;
    if (remaining <= 0) {
      _showError('You can add up to ${ProfileMediaLimits.maxVideos} videos.');
      return;
    }
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 20),
    );
    if (picked == null) return;
    setState(() {
      _videos.add(picked.path);
    });
    _notify();
  }

  void _removePhoto(String path) {
    setState(() {
      _photos.remove(path);
    });
    _notify();
  }

  void _removeVideo(String path) {
    setState(() {
      _videos.remove(path);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._photos.map(
              (path) => _MediaTile(
                path: path,
                isVideo: false,
                onRemove: widget.enabled ? () => _removePhoto(path) : null,
              ),
            ),
            ..._videos.map(
              (path) => _MediaTile(
                path: path,
                isVideo: true,
                onRemove: widget.enabled ? () => _removeVideo(path) : null,
              ),
            ),
            _AddTile(
              icon: Icons.add_a_photo_outlined,
              enabled: widget.enabled,
              onTap: _addPhotos,
            ),
            _AddTile(
              icon: Icons.videocam_outlined,
              enabled: widget.enabled,
              onTap: _addVideo,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Photos ${_photos.length}/${ProfileMediaLimits.maxPhotos} · '
          'Videos ${_videos.length}/${ProfileMediaLimits.maxVideos}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.path,
    required this.isVideo,
    this.onRemove,
  });

  final String path;
  final bool isVideo;
  final VoidCallback? onRemove;

  bool get _isRemote {
    final uri = Uri.tryParse(path);
    return uri != null && uri.hasScheme;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 128,
            color: Colors.grey.shade200,
            child: isVideo
                ? const Center(child: Icon(Icons.videocam, size: 32))
                : _isRemote
                    ? Image.network(path, fit: BoxFit.cover)
                    : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Row(
            children: [
              if (isVideo)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              if (onRemove != null)
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.black87,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white70,
                    shape: const CircleBorder(),
                  ),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 96,
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Icon(icon, color: enabled ? Colors.black87 : Colors.grey),
      ),
    );
  }
}

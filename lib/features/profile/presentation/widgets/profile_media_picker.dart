import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:image_picker/image_picker.dart';

import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/shared/utils/profile_media_limits.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';

enum _MediaPickType { photo, video }

class ProfileMediaSelection {
  final List<String> photos;
  final List<String> videos;
  final int primaryPhotoIndex;

  const ProfileMediaSelection({
    required this.photos,
    required this.videos,
    this.primaryPhotoIndex = 0,
  });
}

class ProfileMediaPicker extends StatefulWidget {
  const ProfileMediaPicker({
    super.key,
    required this.initialPhotos,
    required this.initialVideos,
    required this.onChanged,
    this.initialPrimaryIndex = 0,
    this.enabled = true,
    this.onError,
  });

  final List<String> initialPhotos;
  final List<String> initialVideos;
  final int initialPrimaryIndex;
  final bool enabled;
  final ValueChanged<ProfileMediaSelection> onChanged;
  final ValueChanged<String>? onError;

  @override
  State<ProfileMediaPicker> createState() => _ProfileMediaPickerState();
}

class _ProfileMediaPickerState extends State<ProfileMediaPicker> {
  late List<String> _photos;
  late List<String> _videos;
  late int _primaryPhotoIndex;
  final _picker = ImagePicker();
  final _addPhotoTileKey = GlobalKey();
  final _addVideoTileKey = GlobalKey();
  bool _isPickingMedia = false; // Prevent concurrent picker operations

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.initialPhotos);
    _videos = List.of(widget.initialVideos);
    _primaryPhotoIndex = widget.initialPrimaryIndex.clamp(
      0,
      _photos.isEmpty ? 0 : _photos.length - 1,
    );
  }

  @override
  void didUpdateWidget(covariant ProfileMediaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhotos != widget.initialPhotos ||
        oldWidget.initialVideos != widget.initialVideos ||
        oldWidget.initialPrimaryIndex != widget.initialPrimaryIndex) {
      setState(() {
        _photos = List.of(widget.initialPhotos);
        _videos = List.of(widget.initialVideos);
        _primaryPhotoIndex = widget.initialPrimaryIndex.clamp(
          0,
          _photos.isEmpty ? 0 : _photos.length - 1,
        );
      });
    }
  }

  void _notify() {
    widget.onChanged(
      ProfileMediaSelection(
        photos: List.of(_photos),
        videos: List.of(_videos),
        primaryPhotoIndex: _primaryPhotoIndex,
      ),
    );
  }

  void _setPrimaryPhoto(int index) {
    if (!widget.enabled || index < 0 || index >= _photos.length) return;
    setState(() {
      _primaryPhotoIndex = index;
    });
    _notify();
  }

  void _showError(String message) {
    if (widget.onError != null) {
      widget.onError!(message);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Validate a picked image file for size and dimensions.
  /// Returns null if valid, or an error message string if invalid.
  Future<String?> _validateImage(File file) async {
    // Check file size
    final sizeBytes = await file.length();
    if (sizeBytes > ProfileMediaLimits.maxPhotoSizeBytes) {
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'Photo too large (${sizeMB}MB). Maximum is 10MB.';
    }

    // Check dimensions
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();

      if (width < ProfileMediaLimits.minPhotoDimension ||
          height < ProfileMediaLimits.minPhotoDimension) {
        return 'Photo too small (${width}x$height). Minimum is ${ProfileMediaLimits.minPhotoDimension}x${ProfileMediaLimits.minPhotoDimension}.';
      }
    } catch (e) {
      AppLogger.warning(
        'Image validation: Could not read dimensions',
        error: e,
      );
      // Allow upload if we can't read dimensions — optimizer will handle resize
    }

    return null;
  }

  Future<void> _addPhotos() async {
    if (!widget.enabled || _isPickingMedia) return;
    final l10n = AppLocalizations.of(context);
    final remaining = ProfileMediaLimits.maxPhotos - _photos.length;
    if (remaining <= 0) {
      _showError('You can add up to ${ProfileMediaLimits.maxPhotos} photos.');
      return;
    }

    _isPickingMedia = true;
    try {
      final source = await _pickMediaSource(
        type: _MediaPickType.photo,
        anchorKey: _addPhotoTileKey,
      );
      if (source == null) return;

      final files = await _pickPhotoFiles(source: source, remaining: remaining);
      if (files.isEmpty) return;

      final selected = files.take(remaining).toList();
      final validPaths = <String>[];
      final errors = <String>[];

      for (final xFile in selected) {
        final file = File(xFile.path);
        final error = await _validateImage(file);
        if (error != null) {
          errors.add(error);
        } else {
          validPaths.add(xFile.path);
        }
      }

      if (validPaths.isNotEmpty) {
        setState(() {
          _photos.addAll(validPaths);
        });
        _notify();
      }

      if (errors.isNotEmpty) {
        _showError(
          errors.length == 1
              ? errors.first
              : l10n.photosRejected(errors.length, errors.first),
        );
      } else if (files.length > selected.length) {
        _showError(l10n.photoSlotsAvailable(remaining));
      }
    } on PlatformException catch (e) {
      // Handle "already_active" error gracefully
      AppLogger.error('Image picker error: ${e.code} - ${e.message}');
      if (e.code != 'already_active') {
        _showError('Unable to open photo picker. Please try again.');
      }
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _addVideo() async {
    if (!widget.enabled || _isPickingMedia) return;
    final remaining = ProfileMediaLimits.maxVideos - _videos.length;
    if (remaining <= 0) {
      _showError('You can only add ${ProfileMediaLimits.maxVideos} video.');
      return;
    }

    _isPickingMedia = true;
    try {
      final source = await _pickMediaSource(
        type: _MediaPickType.video,
        anchorKey: _addVideoTileKey,
      );
      if (source == null) return;

      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: ProfileMediaLimits.maxVideoDuration,
      );
      if (picked == null) return;
      setState(() {
        _videos.add(picked.path);
      });
      _notify();
    } on PlatformException catch (e) {
      // Handle "already_active" error gracefully
      AppLogger.error('Video picker error: ${e.code} - ${e.message}');
      if (e.code != 'already_active') {
        _showError('Unable to open video picker. Please try again.');
      }
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<List<XFile>> _pickPhotoFiles({
    required ImageSource source,
    required int remaining,
  }) async {
    if (source == ImageSource.camera) {
      final captured = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 72,
        maxWidth: 1440,
        requestFullMetadata: false,
      );
      return captured == null ? const [] : [captured];
    }

    return _picker.pickMultiImage(
      imageQuality: 72,
      maxWidth: 1440,
      requestFullMetadata: false,
      limit: remaining,
    );
  }

  Future<ImageSource?> _pickMediaSource({
    required _MediaPickType type,
    required GlobalKey anchorKey,
  }) {
    if (_shouldUseAnchoredPicker()) {
      return _showAnchoredSourceMenu(type: type, anchorKey: anchorKey);
    }
    return _showBottomSheetSourceMenu(type: type);
  }

  bool _shouldUseAnchoredPicker() {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return false;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS && mediaQuery.size.shortestSide >= 600;
  }

  String _cameraLabel(_MediaPickType type) {
    final l10n = AppLocalizations.of(context);
    if (type == _MediaPickType.photo) {
      return l10n.takePhoto;
    }
    return 'Record Video';
  }

  String _galleryLabel() => AppLocalizations.of(context).chooseFromGallery;

  Future<ImageSource?> _showBottomSheetSourceMenu({
    required _MediaPickType type,
  }) {
    final cameraLabel = _cameraLabel(type);
    final galleryLabel = _galleryLabel();
    final cameraIcon = type == _MediaPickType.photo
        ? Icons.photo_camera_outlined
        : Icons.videocam_outlined;
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(cameraIcon),
                title: Text(cameraLabel),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(galleryLabel),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<ImageSource?> _showAnchoredSourceMenu({
    required _MediaPickType type,
    required GlobalKey anchorKey,
  }) {
    final anchorContext = anchorKey.currentContext;
    final overlayBox =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    final buttonBox = anchorContext?.findRenderObject() as RenderBox?;

    if (overlayBox == null || buttonBox == null) {
      return _showBottomSheetSourceMenu(type: type);
    }

    final targetRect = buttonBox.localToGlobal(
          Offset.zero,
          ancestor: overlayBox,
        ) &
        buttonBox.size;
    final position = RelativeRect.fromRect(
      targetRect,
      Offset.zero & overlayBox.size,
    );
    final cameraLabel = _cameraLabel(type);
    final galleryLabel = _galleryLabel();

    return showMenu<ImageSource>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<ImageSource>(
          value: ImageSource.camera,
          child: Text(cameraLabel, overflow: TextOverflow.ellipsis),
        ),
        PopupMenuItem<ImageSource>(
          value: ImageSource.gallery,
          child: Text(galleryLabel, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      // Adjust primary index if needed
      if (_photos.isEmpty) {
        _primaryPhotoIndex = 0;
      } else if (_primaryPhotoIndex >= _photos.length) {
        _primaryPhotoIndex = _photos.length - 1;
      } else if (index < _primaryPhotoIndex) {
        _primaryPhotoIndex--;
      } else if (index == _primaryPhotoIndex &&
          _primaryPhotoIndex >= _photos.length) {
        _primaryPhotoIndex = _photos.length - 1;
      }
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
            for (int i = 0; i < _photos.length; i++)
              _MediaTile(
                path: _photos[i],
                isVideo: false,
                isPrimary: i == _primaryPhotoIndex,
                onRemove: widget.enabled ? () => _removePhoto(i) : null,
                onTap: widget.enabled ? () => _setPrimaryPhoto(i) : null,
              ),
            ..._videos.map(
              (path) => _MediaTile(
                path: path,
                isVideo: true,
                onRemove: widget.enabled ? () => _removeVideo(path) : null,
              ),
            ),
            _AddTile(
              key: _addPhotoTileKey,
              icon: Icons.add_a_photo_outlined,
              enabled: widget.enabled,
              onTap: _addPhotos,
            ),
            _AddTile(
              key: _addVideoTileKey,
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
        if (_photos.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Text(
              'Tap a photo to set as display picture',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DsColors.ink300,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.path,
    required this.isVideo,
    this.isPrimary = false,
    this.onRemove,
    this.onTap,
  });

  final String path;
  final bool isVideo;
  final bool isPrimary;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  bool get _isRemote {
    final uri = Uri.tryParse(path);
    return uri != null && uri.hasScheme;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 96,
                height: 128,
                decoration: BoxDecoration(
                  color: DsColors.skeletonLight,
                  border: isPrimary
                      ? Border.all(color: DsColors.primary, width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isPrimary ? 9 : 12),
                  child: isVideo
                      ? const Center(child: Icon(Icons.videocam, size: 32))
                      : _isRemote
                      ? CachedNetworkImage(imageUrl: path, fit: BoxFit.cover)
                      : Image.file(File(path), fit: BoxFit.cover),
                ),
              ),
            ),
            // Primary photo badge
            if (isPrimary && !isVideo)
              PositionedDirectional(
                start: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DsColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: DsColors.surfaceLight, size: 12),
                      SizedBox(width: 2),
                      Text(
                        'Display',
                        style: TextStyle(
                          color: DsColors.surfaceLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            PositionedDirectional(
              end: 4,
              top: 4,
              child: Row(
                children: [
                  if (isVideo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DsColors.ink900.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Video',
                        style: TextStyle(
                          color: DsColors.surfaceLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (onRemove != null)
                    IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: DsColors.ink900.withValues(alpha: 0.87),
                      style: IconButton.styleFrom(
                        backgroundColor: DsColors.surfaceLight.withValues(
                          alpha: 0.7,
                        ),
                        shape: const CircleBorder(),
                      ),
                      onPressed: onRemove,
                      icon: const Icon(Icons.close),
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

class _AddTile extends StatelessWidget {
  const _AddTile({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 96,
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DsColors.borderLight, width: 2),
          ),
          child: Icon(
            icon,
            color: enabled
                ? DsColors.textPrimaryLight
                : DsColors.textMutedLight,
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crushhour/core/constants/network_constants.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A memory-efficient cached network image widget with proper caching strategy.
///
/// Features:
/// - LRU cache with configurable max entries
/// - Placeholder and error widgets
/// - Fade-in animation
/// - Memory management with soft references
/// - Retry on failure
class CachedNetworkImage extends StatefulWidget {
  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = NetworkConstants.imageFadeInDuration,
    this.borderRadius,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.onRetry,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final VoidCallback? onRetry;

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  ImageProvider? _imageProvider;
  bool _isLoading = true;
  bool _hasError = false;

  /// Check if the URL is a remote URL (http/https) or a local file path
  bool _isRemoteUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Uint8List? bytes;

      // Check if this is a local file path or a remote URL
      if (_isRemoteUrl(widget.imageUrl)) {
        // Remote URL - fetch from network with caching
        bytes = await NetworkImageCache.instance.get(widget.imageUrl);
      } else {
        // Local file path - load directly from file system
        final file = File(widget.imageUrl);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (!mounted) return;

      if (bytes != null) {
        setState(() {
          _imageProvider = MemoryImage(bytes!);
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = widget.placeholder ?? _buildPlaceholder();
    } else if (_hasError) {
      content = widget.errorWidget ?? _buildErrorWidget();
    } else if (_imageProvider != null) {
      content = AnimatedSwitcher(
        duration: widget.fadeInDuration,
        child: Image(
          key: ValueKey(widget.imageUrl),
          image: _imageProvider!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          errorBuilder: (_, _, _) =>
              widget.errorWidget ?? _buildErrorWidget(),
        ),
      );
    } else {
      content = widget.errorWidget ?? _buildErrorWidget();
    }

    // Wrap with semantics for accessibility
    Widget result;
    if (widget.borderRadius != null) {
      result = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: content,
        ),
      );
    } else {
      result = SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      );
    }

    // Apply accessibility semantics
    if (widget.excludeFromSemantics) {
      return ExcludeSemantics(child: result);
    }
    if (widget.semanticLabel != null) {
      return Semantics(
        image: true,
        label: _isLoading
            ? 'Loading image'
            : _hasError
                ? 'Image failed to load'
                : widget.semanticLabel,
        child: result,
      );
    }
    return result;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: DsColors.skeletonLight,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: DsColors.skeletonLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined,
                color: DsColors.textMutedLight, size: 32),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  widget.onRetry?.call();
                  _loadImage();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DsColors.dividerLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh,
                          size: 14, color: DsColors.textMutedLight),
                      SizedBox(width: 4),
                      Text('Retry',
                          style: TextStyle(
                              fontSize: 12, color: DsColors.textMutedLight)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Manually retry loading the image
  void retry() {
    _loadImage();
  }
}

/// Preload priority for images.
enum ImagePreloadPriority {
  /// Current visible image - highest priority
  immediate,

  /// Next 1-2 images - high priority
  high,

  /// Background preview images - low priority
  low,
}

/// LRU image cache with memory management and priority-based preloading.
class NetworkImageCache {
  static final NetworkImageCache instance = NetworkImageCache._();
  NetworkImageCache._();

  static const int _maxCacheSize = 50;
  static const int _maxMemoryBytes = 50 * 1024 * 1024; // 50 MB
  static const int _lowMemoryThreshold =
      40 * 1024 * 1024; // 40 MB - start being conservative
  static const int _criticalMemoryThreshold =
      45 * 1024 * 1024; // 45 MB - aggressive eviction

  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  final Map<String, Completer<Uint8List?>> _pending = {};
  final Set<String> _priorityUrls = {}; // Track high-priority URLs
  int _currentMemoryBytes = 0;
  bool _isUnderMemoryPressure = false;

  /// Get current memory usage in bytes.
  int get currentMemoryBytes => _currentMemoryBytes;

  /// Get current cache entry count.
  int get cacheSize => _cache.length;

  /// Check if cache is under memory pressure.
  bool get isUnderMemoryPressure => _isUnderMemoryPressure;

  /// Get an image from cache or fetch it.
  Future<Uint8List?> get(String url,
      {ImagePreloadPriority priority = ImagePreloadPriority.immediate}) async {
    // Check cache first
    if (_cache.containsKey(url)) {
      // Move to end (most recently used)
      final bytes = _cache.remove(url)!;
      _cache[url] = bytes;
      return bytes;
    }

    // Check if already fetching
    if (_pending.containsKey(url)) {
      return _pending[url]!.future;
    }

    // Under critical memory pressure, skip low priority preloads
    if (priority == ImagePreloadPriority.low &&
        _currentMemoryBytes > _criticalMemoryThreshold) {
      return null;
    }

    // Start fetching
    final completer = Completer<Uint8List?>();
    _pending[url] = completer;

    // Track high priority URLs for smarter eviction
    if (priority == ImagePreloadPriority.immediate ||
        priority == ImagePreloadPriority.high) {
      _priorityUrls.add(url);
    }

    try {
      final bytes = await _fetchImage(url);
      if (bytes != null) {
        _addToCache(url, bytes, priority: priority);
      }
      completer.complete(bytes);
    } catch (e) {
      completer.complete(null);
    } finally {
      _pending.remove(url);
    }

    return completer.future;
  }

  Future<Uint8List?> _fetchImage(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'image/*'},
      ).timeout(NetworkConstants.imageLoadTimeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _addToCache(String url, Uint8List bytes,
      {ImagePreloadPriority priority = ImagePreloadPriority.immediate}) {
    // Update memory pressure state
    _isUnderMemoryPressure = _currentMemoryBytes > _lowMemoryThreshold;

    // Evict old entries if needed - prioritize keeping high-priority images
    while (_cache.length >= _maxCacheSize ||
        _currentMemoryBytes + bytes.length > _maxMemoryBytes) {
      if (_cache.isEmpty) break;

      // Find best candidate for eviction (prefer non-priority URLs)
      String? keyToEvict;
      for (final key in _cache.keys) {
        if (!_priorityUrls.contains(key)) {
          keyToEvict = key;
          break;
        }
      }
      // If all are priority, evict oldest anyway
      keyToEvict ??= _cache.keys.first;

      final oldestBytes = _cache.remove(keyToEvict);
      _priorityUrls.remove(keyToEvict);
      if (oldestBytes != null) {
        _currentMemoryBytes -= oldestBytes.length;
      }
    }

    _cache[url] = bytes;
    _currentMemoryBytes += bytes.length;
  }

  /// Preload images into cache with priority support.
  /// Images are loaded in order of priority: immediate > high > low.
  Future<void> preload(
    List<String> urls, {
    ImagePreloadPriority priority = ImagePreloadPriority.high,
  }) async {
    if (urls.isEmpty) return;

    // Under memory pressure, limit preloading
    final effectiveUrls = _isUnderMemoryPressure ? urls.take(2).toList() : urls;

    await Future.wait(
      effectiveUrls.map((url) => get(url, priority: priority)),
      eagerError: false,
    );
  }

  /// Preload with prioritized ordering - closer cards first.
  /// [immediateUrls] - Current card (priority: immediate)
  /// [highUrls] - Next 1-2 cards (priority: high)
  /// [lowUrls] - Preview cards (priority: low)
  Future<void> preloadWithPriority({
    List<String>? immediateUrls,
    List<String>? highUrls,
    List<String>? lowUrls,
  }) async {
    // Load immediate first
    if (immediateUrls != null && immediateUrls.isNotEmpty) {
      await preload(immediateUrls, priority: ImagePreloadPriority.immediate);
    }

    // Then high priority (don't wait, let them load in parallel)
    if (highUrls != null && highUrls.isNotEmpty) {
      preload(highUrls, priority: ImagePreloadPriority.high);
    }

    // Finally low priority (background, don't wait)
    if (lowUrls != null && lowUrls.isNotEmpty && !_isUnderMemoryPressure) {
      preload(lowUrls, priority: ImagePreloadPriority.low);
    }
  }

  /// Trim cache to reduce memory usage.
  /// Call this when app receives memory warning.
  void trimCache({int targetEntries = 20}) {
    while (_cache.length > targetEntries) {
      // Evict non-priority first
      String? keyToEvict;
      for (final key in _cache.keys) {
        if (!_priorityUrls.contains(key)) {
          keyToEvict = key;
          break;
        }
      }
      keyToEvict ??= _cache.keys.first;

      final bytes = _cache.remove(keyToEvict);
      _priorityUrls.remove(keyToEvict);
      if (bytes != null) {
        _currentMemoryBytes -= bytes.length;
      }
    }
    _isUnderMemoryPressure = _currentMemoryBytes > _lowMemoryThreshold;
  }

  /// Clear the cache.
  void clear() {
    _cache.clear();
    _priorityUrls.clear();
    _currentMemoryBytes = 0;
    _isUnderMemoryPressure = false;
  }

  /// Evict a specific URL from cache.
  void evict(String url) {
    final bytes = _cache.remove(url);
    _priorityUrls.remove(url);
    if (bytes != null) {
      _currentMemoryBytes -= bytes.length;
    }
  }

  /// Mark URLs as high priority (won't be evicted first).
  void markAsPriority(List<String> urls) {
    _priorityUrls.addAll(urls);
  }

  /// Remove priority status from URLs.
  void removePriority(List<String> urls) {
    _priorityUrls.removeAll(urls);
  }
}

/// In-memory image provider.
class MemoryImage extends ImageProvider<MemoryImage> {
  const MemoryImage(this.bytes);

  final Uint8List bytes;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
      MemoryImage key, ImageDecoderCallback decode) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is MemoryImage && other.bytes == bytes;
  }

  @override
  int get hashCode => bytes.hashCode;
}

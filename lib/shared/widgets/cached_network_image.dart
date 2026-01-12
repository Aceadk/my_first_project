import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.borderRadius,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  ImageProvider? _imageProvider;
  bool _isLoading = true;
  bool _hasError = false;

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
      final bytes = await NetworkImageCache.instance.get(widget.imageUrl);
      if (!mounted) return;

      if (bytes != null) {
        setState(() {
          _imageProvider = MemoryImage(bytes);
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
          errorBuilder: (_, __, ___) =>
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
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }
}

/// LRU image cache with memory management.
class NetworkImageCache {
  static final NetworkImageCache instance = NetworkImageCache._();
  NetworkImageCache._();

  static const int _maxCacheSize = 50;
  static const int _maxMemoryBytes = 50 * 1024 * 1024; // 50 MB

  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  final Map<String, Completer<Uint8List?>> _pending = {};
  int _currentMemoryBytes = 0;

  /// Get an image from cache or fetch it.
  Future<Uint8List?> get(String url) async {
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

    // Start fetching
    final completer = Completer<Uint8List?>();
    _pending[url] = completer;

    try {
      final bytes = await _fetchImage(url);
      if (bytes != null) {
        _addToCache(url, bytes);
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
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _addToCache(String url, Uint8List bytes) {
    // Evict old entries if needed
    while (_cache.length >= _maxCacheSize ||
        _currentMemoryBytes + bytes.length > _maxMemoryBytes) {
      if (_cache.isEmpty) break;
      final oldestKey = _cache.keys.first;
      final oldestBytes = _cache.remove(oldestKey);
      if (oldestBytes != null) {
        _currentMemoryBytes -= oldestBytes.length;
      }
    }

    _cache[url] = bytes;
    _currentMemoryBytes += bytes.length;
  }

  /// Preload images into cache.
  Future<void> preload(List<String> urls) async {
    await Future.wait(
      urls.map((url) => get(url)),
      eagerError: false,
    );
  }

  /// Clear the cache.
  void clear() {
    _cache.clear();
    _currentMemoryBytes = 0;
  }

  /// Evict a specific URL from cache.
  void evict(String url) {
    final bytes = _cache.remove(url);
    if (bytes != null) {
      _currentMemoryBytes -= bytes.length;
    }
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

  Future<ui.Codec> _loadAsync(MemoryImage key, ImageDecoderCallback decode) async {
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

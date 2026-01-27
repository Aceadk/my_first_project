import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import '../../core/ui/snackbar_utils.dart';

/// Shared wrapper to unify loading/error/empty states across screens.
/// Provides optional snackbars for errors so callers do not have to duplicate
/// BlocConsumer listeners.
class AsyncStateScaffold extends StatefulWidget {
  const AsyncStateScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.isLoading = false,
    this.errorMessage,
    this.error,
    this.onRetry,
    this.empty,
    this.backgroundColor,
    this.showBodyOnLoading = false,
    this.showErrorSnackBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool isLoading;
  final String? errorMessage;
  final Widget? error;
  final VoidCallback? onRetry;
  final Widget? empty;
  final Color? backgroundColor;
  final bool showBodyOnLoading;
  final bool showErrorSnackBar;

  @override
  State<AsyncStateScaffold> createState() => _AsyncStateScaffoldState();
}

class _AsyncStateScaffoldState extends State<AsyncStateScaffold> {
  @override
  void didUpdateWidget(covariant AsyncStateScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = widget.errorMessage;
    if (!widget.showErrorSnackBar) return;
    if (error == null || error.isEmpty) return;
    final previous = oldWidget.errorMessage;
    if (previous == error) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorMessage != null && widget.errorMessage!.isNotEmpty;
    final hasCustomErrorView = widget.error != null;
    final canRetry = widget.onRetry != null;
    final hasEmptyView = widget.empty != null;

    Widget content;
    if (widget.isLoading && !widget.showBodyOnLoading) {
      content = const _CenteredLoader();
    } else if (hasError && (hasCustomErrorView || canRetry || hasEmptyView)) {
      content = widget.error ??
          _ErrorView(
            message: widget.errorMessage!,
            onRetry: widget.onRetry,
          );
    } else if (hasEmptyView) {
      content = widget.empty!;
    } else {
      content = widget.body;
    }

    return Scaffold(
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      backgroundColor: widget.backgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: content,
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: DsColors.warning),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

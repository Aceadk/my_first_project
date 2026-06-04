import 'dart:async';

import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// In-app PiP overlay for active video calls.
///
/// This is a Flutter overlay fallback used until native Android/iOS PiP
/// is wired across platform layers.
class CallPiPOverlayService {
  CallPiPOverlayService._();

  static final CallPiPOverlayService instance = CallPiPOverlayService._();

  OverlayEntry? _entry;
  Offset _position = const Offset(16, 120);
  StreamSubscription<CallUIState>? _stateSub;
  CallScreenArgs? _args;

  bool get isVisible => _entry != null;

  void show({required BuildContext context, required CallScreenArgs args}) {
    hide();
    _args = args;

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (overlayContext) {
        final media = MediaQuery.of(overlayContext);
        final maxX = media.size.width - 140;
        final maxY = media.size.height - 190;
        final left = _position.dx.clamp(8.0, maxX < 8 ? 8.0 : maxX);
        final top = _position.dy.clamp(
          media.padding.top + 8,
          maxY < media.padding.top + 8 ? media.padding.top + 8 : maxY,
        );

        return PositionedDirectional(
          start: left,
          top: top,
          child: _PipVideoOverlay(
            args: args,
            onClose: hide,
            onTap: () {
              final currentArgs = _args;
              if (currentArgs == null) return;
              hide();
              GoRouter.of(overlayContext).push(
                CrushRoutes.call,
                extra: CallScreenArgs(
                  matchId: currentArgs.matchId,
                  isVideoCall: currentArgs.isVideoCall,
                  matchName: currentArgs.matchName,
                  matchPhotoUrl: currentArgs.matchPhotoUrl,
                  isIncoming: true,
                ),
              );
            },
            onDragDelta: (delta) {
              _position += delta;
              _entry?.markNeedsBuild();
            },
          ),
        );
      },
    );

    overlay.insert(_entry!);
    _stateSub = context.read<CallManagerRepository>().callStateStream.listen((
      state,
    ) {
      if (state == CallUIState.ended) {
        hide();
      }
    });
  }

  void hide() {
    _stateSub?.cancel();
    _stateSub = null;
    _entry?.remove();
    _entry = null;
    _args = null;
  }
}

class _PipVideoOverlay extends StatelessWidget {
  const _PipVideoOverlay({
    required this.args,
    required this.onTap,
    required this.onClose,
    required this.onDragDelta,
  });

  final CallScreenArgs args;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final ValueChanged<Offset> onDragDelta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.callPipFloatingWindow,
      button: true,
      child: GestureDetector(
        onPanUpdate: (details) => onDragDelta(details.delta),
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 132,
            height: 176,
            decoration: BoxDecoration(
              color: DsColors.ink900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DsColors.surfaceLight.withValues(alpha: 0.26),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: DsColors.ink900.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: args.matchPhotoUrl?.isNotEmpty == true
                        ? CachedImage(
                            imageUrl: args.matchPhotoUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: AlignmentDirectional.topStart,
                                end: AlignmentDirectional.bottomEnd,
                                colors: [
                                  DsColors.primary.withValues(alpha: 0.5),
                                  DsColors.secondary.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.14),
                            Colors.black.withValues(alpha: 0.56),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.callPipClose,
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: DsColors.surfaceLight,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 10,
                    end: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.callPipTapToReturn,
                          style: const TextStyle(
                            color: DsColors.surfaceLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          args.matchName?.trim().isNotEmpty == true
                              ? args.matchName!.trim()
                              : l10n.callPipActiveCall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: DsColors.surfaceLight.withValues(
                              alpha: 0.92,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

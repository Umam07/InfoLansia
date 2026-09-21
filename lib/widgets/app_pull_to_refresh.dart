import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// A fluid, Telegram/Dynamic Island style floating status pill pull-to-refresh container.
///
/// Features:
/// 1. Stationary content (zero rubber-band stretch/gap).
/// 2. Interactive retraction: if the user pulls down to reveal the capsule,
///    and then drags back up without releasing, the capsule immediately
///    retracts back up and cancels smoothly, allowing the screen to scroll naturally.
/// 3. Informative status text & rotating sync icon.
/// 4. Fully solid & clean (Zero Glow, Zero Gradient).
class AppPullToRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final double topOffset;
  final double triggerDistance;

  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.topOffset = 12.0,
    this.triggerDistance = 65.0,
  });

  @override
  State<AppPullToRefresh> createState() => _AppPullToRefreshState();
}

class _AppPullToRefreshState extends State<AppPullToRefresh>
    with TickerProviderStateMixin {
  double _dragDistance = 0.0;
  bool _isRefreshing = false;
  late final AnimationController _animController;
  late final AnimationController _spinController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _animateTo(double target, {VoidCallback? onComplete}) {
    _animController.stop();
    final start = _dragDistance;
    _animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragDistance = _animation!.value;
          });
        }
      });

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _animController.removeStatusListener(statusListener);
        onComplete?.call();
      }
    }

    _animController.addStatusListener(statusListener);
    _animController.forward(from: 0.0);
  }

  void _startRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    _spinController.repeat();
    _animateTo(52.0);

    try {
      await widget.onRefresh();
    } catch (_) {}

    if (mounted) {
      _animateTo(0.0, onComplete: () {
        if (mounted) {
          _spinController.stop();
          _spinController.reset();
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    }
  }

  void _cancelRefresh() {
    _animateTo(0.0);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is OverscrollNotification) {
      // User is dragging down beyond top edge
      if (notification.overscroll < 0) {
        setState(() {
          _dragDistance =
              (_dragDistance - notification.overscroll * 0.55).clamp(0.0, 110.0);
        });
      }
    } else if (notification is ScrollUpdateNotification) {
      // If user drags back up while still holding, retract the capsule smoothly
      if (_dragDistance > 0 && notification.scrollDelta != null) {
        if (notification.scrollDelta! > 0) {
          setState(() {
            _dragDistance =
                (_dragDistance - notification.scrollDelta! * 0.9).clamp(0.0, 110.0);
          });
        }
      }
    } else if (notification is ScrollEndNotification) {
      // User lifted finger
      if (_dragDistance >= widget.triggerDistance) {
        _startRefresh();
      } else if (_dragDistance > 0) {
        _cancelRefresh();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = _dragDistance > 0 || _isRefreshing;
    final progress = (_dragDistance / widget.triggerDistance).clamp(0.0, 1.0);
    final indicatorTop = widget.topOffset + (_dragDistance * 0.65).clamp(0.0, 48.0);
    final scale = (progress * 0.5 + 0.5).clamp(0.5, 1.0);
    final opacity = progress.clamp(0.0, 1.0);

    final String statusText;
    final Color contentColor;
    if (_isRefreshing) {
      statusText = 'Memperbarui data...';
      contentColor = AppColors.primary;
    } else if (progress >= 1.0) {
      statusText = 'Lepaskan untuk memuat';
      contentColor = AppColors.primary;
    } else {
      statusText = 'Tarik untuk menyegarkan';
      contentColor = AppColors.textSecondary;
    }

    return Stack(
      children: [
        // Main scrollable content
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.child,
          ),
        ),

        // Floating Status Pill (Dynamic Island / Telegram style)
        if (showIndicator)
          Positioned(
            top: indicatorTop,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(21.0),
                      border: Border.all(
                        color: AppColors.borderSubtle.withValues(alpha: 0.9),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Rotating Sync Icon
                        if (_isRefreshing)
                          RotationTransition(
                            turns: _spinController,
                            child: const Icon(
                              Icons.sync_rounded,
                              size: 19,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          Transform.rotate(
                            angle: progress * math.pi * 2,
                            child: Icon(
                              Icons.sync_rounded,
                              size: 19,
                              color: contentColor,
                            ),
                          ),
                        const SizedBox(width: 8.0),
                        // Informative Status Text
                        Text(
                          statusText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: _isRefreshing || progress >= 1.0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: contentColor,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

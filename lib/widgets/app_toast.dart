import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

enum AppToastType { success, info, warning, error }

class AppToast {
  static OverlayEntry? _currentEntry;
  static GlobalKey<_ToastWidgetState>? _currentKey;

  static void show({
    required BuildContext context,
    required String message,
    String? title,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    // Dismiss any existing toast immediately
    if (_currentEntry != null) {
      _currentKey?.currentState?.dismiss(immediate: true);
      _currentEntry?.remove();
      _currentEntry = null;
      _currentKey = null;
    }

    final overlayState = Overlay.of(context);
    final key = GlobalKey<_ToastWidgetState>();
    _currentKey = key;

    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    final entry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          key: key,
          message: message,
          title: title,
          type: type,
          duration: duration,
          topPadding: topPadding,
          onDismiss: () {
            if (_currentEntry != null) {
              _currentEntry?.remove();
              _currentEntry = null;
              _currentKey = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final AppToastType type;
  final Duration duration;
  final double topPadding;
  final VoidCallback onDismiss;

  const _ToastWidget({
    super.key,
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    required this.topPadding,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;
  bool _isDismissing = false;
  Timer? _dismissTimer;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      dismiss();
    });
  }

  void dismiss({bool immediate = false}) {
    if (_isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();

    if (immediate) {
      widget.onDismiss();
    } else {
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeIn).then((_) {
        widget.onDismiss();
      });
    }
  }

  Color get _typeColor {
    switch (widget.type) {
      case AppToastType.success:
        return AppColors.primary;
      case AppToastType.error:
        return AppColors.error;
      case AppToastType.warning:
        return AppColors.statusWarning;
      case AppToastType.info:
        return const Color(0xFF0284C7); // Sky Blue
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.error:
        return Icons.error_rounded;
      case AppToastType.warning:
        return Icons.warning_rounded;
      case AppToastType.info:
        return Icons.info_rounded;
    }
  }

  String get _defaultTitle {
    switch (widget.type) {
      case AppToastType.success:
        return 'Berhasil';
      case AppToastType.error:
        return 'Error';
      case AppToastType.warning:
        return 'Perhatian';
      case AppToastType.info:
        return 'Informasi';
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding + 16.0 + _dragOffset,
      left: 16.0,
      right: 16.0,
      child: SafeArea(
        top: false,
        bottom: false,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              // Only allow dragging upwards (negative offset)
              if (details.primaryDelta! < 0) {
                _dragOffset += details.primaryDelta!;
              }
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset < -20.0 || details.primaryVelocity! < -100.0) {
              dismiss();
            } else {
              setState(() {
                _dragOffset = 0.0;
              });
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _offsetAnimation.value * 50.0,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24.0,
                          offset: const Offset(0.0, 8.0),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left status circle icon
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _typeIcon,
                            color: _typeColor,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 16.0),

                        // Middle title/subtitle message texts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title ?? _defaultTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                widget.message,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),

                        // Right drag handle indicator (resembling dynamic island pill)
                        Opacity(
                          opacity: 0.3,
                          child: Container(
                            width: 4.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                              color: AppColors.outline,
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

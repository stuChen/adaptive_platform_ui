import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';

const Duration _modalSheetEnterDuration = Duration(milliseconds: 350);
const Duration _modalSheetExitDuration = Duration(milliseconds: 250);
const Cubic _modalSheetEnterCurve = Cubic(0.1, 0.8, 0.2, 1.0);
const Cubic _modalSheetExitCurve = Cubic(0.5, 0, 0.7, 0.2);

/// Sheet detents that mirror SwiftUI presentation detents.
enum AdaptivePresentationDetent {
  /// Roughly half-height sheet.
  medium,

  /// Large sheet that leaves only a small top margin.
  large,
}

/// Presents adaptive modal sheets with SwiftUI-like defaults.
class AdaptiveModalSheet {
  AdaptiveModalSheet._();

  /// Shows a modal sheet.
  ///
  /// The defaults match:
  ///
  /// ```swift
  /// .presentationDetents([.large])
  /// .presentationDragIndicator(.hidden)
  /// .presentationCornerRadius(34)
  /// ```
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    List<AdaptivePresentationDetent> presentationDetents = const [
      AdaptivePresentationDetent.large,
    ],
    bool showDragIndicator = false,
    double cornerRadius = 34,
    bool barrierDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
    bool useSafeArea = true,
    double navigationBarTopPadding = 10,
    Color? backgroundColor,
    Color? barrierColor,
    String? barrierLabel,
    RouteSettings? routeSettings,
  }) {
    assert(presentationDetents.isNotEmpty, 'At least one detent is required.');

    return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
      _AdaptiveModalSheetRoute<T>(
        builder: builder,
        presentationDetents: presentationDetents,
        showDragIndicator: showDragIndicator,
        cornerRadius: cornerRadius,
        barrierDismissible: barrierDismissible,
        enableDrag: enableDrag,
        useSafeArea: useSafeArea,
        navigationBarTopPadding: navigationBarTopPadding,
        backgroundColor: backgroundColor,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        settings: routeSettings,
      ),
    );
  }
}

/// Marks descendants as being presented inside an [AdaptiveModalSheet].
class AdaptiveModalSheetScope extends InheritedWidget {
  const AdaptiveModalSheetScope({
    super.key,
    required this.navigationBarTopPadding,
    required super.child,
  });

  /// Extra top spacing used by sheet-scoped adaptive app bars.
  final double navigationBarTopPadding;

  /// Returns the nearest [AdaptiveModalSheetScope], if any.
  static AdaptiveModalSheetScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveModalSheetScope>();
  }

  /// Whether [context] is below an [AdaptiveModalSheetScope].
  static bool isInSheet(BuildContext context) {
    return maybeOf(context) != null;
  }

  @override
  bool updateShouldNotify(AdaptiveModalSheetScope oldWidget) {
    return oldWidget.navigationBarTopPadding != navigationBarTopPadding;
  }
}

class _AdaptiveModalSheetRoute<T> extends PopupRoute<T> {
  _AdaptiveModalSheetRoute({
    required this.builder,
    required this.presentationDetents,
    required this.showDragIndicator,
    required this.cornerRadius,
    required this.barrierDismissible,
    required this.enableDrag,
    required this.useSafeArea,
    required this.navigationBarTopPadding,
    required this.backgroundColor,
    required Color? barrierColor,
    required String? barrierLabel,
    super.settings,
  }) : _barrierColor = barrierColor ?? Colors.black54,
       _barrierLabel = barrierLabel ?? 'Dismiss';

  final WidgetBuilder builder;
  final List<AdaptivePresentationDetent> presentationDetents;
  final bool showDragIndicator;
  final double cornerRadius;
  @override
  final bool barrierDismissible;
  final bool enableDrag;
  final bool useSafeArea;
  final double navigationBarTopPadding;
  final Color? backgroundColor;
  final Color _barrierColor;
  final String _barrierLabel;

  @override
  Color get barrierColor => _barrierColor;

  @override
  String get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => _modalSheetEnterDuration;

  @override
  Duration get reverseTransitionDuration => _modalSheetExitDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _AdaptiveModalSheetContainer(
      animation: animation,
      presentationDetent: _largestDetent(),
      showDragIndicator: showDragIndicator,
      cornerRadius: cornerRadius,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      navigationBarTopPadding: navigationBarTopPadding,
      backgroundColor: backgroundColor,
      child: builder(context),
    );
  }

  AdaptivePresentationDetent _largestDetent() {
    if (presentationDetents.contains(AdaptivePresentationDetent.large)) {
      return AdaptivePresentationDetent.large;
    }
    return AdaptivePresentationDetent.medium;
  }
}

class _AdaptiveModalSheetContainer extends StatefulWidget {
  const _AdaptiveModalSheetContainer({
    required this.animation,
    required this.presentationDetent,
    required this.showDragIndicator,
    required this.cornerRadius,
    required this.enableDrag,
    required this.useSafeArea,
    required this.navigationBarTopPadding,
    required this.backgroundColor,
    required this.child,
  });

  final Animation<double> animation;
  final AdaptivePresentationDetent presentationDetent;
  final bool showDragIndicator;
  final double cornerRadius;
  final bool enableDrag;
  final bool useSafeArea;
  final double navigationBarTopPadding;
  final Color? backgroundColor;
  final Widget child;

  @override
  State<_AdaptiveModalSheetContainer> createState() =>
      _AdaptiveModalSheetContainerState();
}

class _AdaptiveModalSheetContainerState
    extends State<_AdaptiveModalSheetContainer> {
  static const double _dismissDistance = 96;
  static const double _dismissVelocity = 700;
  static const Duration _dragResetDuration = Duration(milliseconds: 220);

  double _dragOffset = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag) return;

    final nextOffset = (_dragOffset + details.delta.dy).clamp(
      0.0,
      double.infinity,
    );

    if (nextOffset == _dragOffset) return;

    setState(() {
      _dragOffset = nextOffset;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enableDrag) return;

    final shouldDismiss =
        _dragOffset >= _dismissDistance ||
        (details.primaryVelocity != null &&
            details.primaryVelocity! >= _dismissVelocity);

    if (shouldDismiss) {
      Navigator.of(context).maybePop();
      return;
    }

    if (_dragOffset == 0) return;

    setState(() {
      _dragOffset = 0;
    });
  }

  void _handleDragCancel() {
    if (!widget.enableDrag || _dragOffset == 0) return;

    setState(() {
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;
    final maxHeight = _sheetHeight(mediaQuery);
    final effectiveBackgroundColor =
        widget.backgroundColor ?? _defaultBackgroundColor(context);
    final isClosing = widget.animation.status == AnimationStatus.reverse;
    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: isClosing ? _modalSheetExitCurve : _modalSheetEnterCurve,
      reverseCurve: isClosing ? _modalSheetEnterCurve : _modalSheetExitCurve,
    );

    return AnimatedPadding(
      duration: _modalSheetExitDuration,
      curve: _modalSheetEnterCurve,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: AnimatedContainer(
            duration: _dragOffset == 0 ? _dragResetDuration : Duration.zero,
            curve: _modalSheetEnterCurve,
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            width: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: widget.enableDrag
                  ? _handleDragUpdate
                  : null,
              onVerticalDragEnd: widget.enableDrag ? _handleDragEnd : null,
              onVerticalDragCancel: widget.enableDrag
                  ? _handleDragCancel
                  : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(widget.cornerRadius),
                  ),
                  child: Material(
                    color: effectiveBackgroundColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showDragIndicator)
                          const _ModalSheetDragIndicator(),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _ModalSheetMediaQuery(
                            useSafeArea: widget.useSafeArea,
                            navigationBarTopPadding:
                                widget.navigationBarTopPadding,
                            child: widget.child,
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

  double _sheetHeight(MediaQueryData mediaQuery) {
    final topGap = widget.presentationDetent == AdaptivePresentationDetent.large
        ? 8.0
        : mediaQuery.size.height * 0.5;
    final topPadding =
        widget.presentationDetent == AdaptivePresentationDetent.large
        ? mediaQuery.viewPadding.top
        : 0.0;

    return (mediaQuery.size.height - topPadding - topGap)
        .clamp(0.0, mediaQuery.size.height)
        .toDouble();
  }

  Color _defaultBackgroundColor(BuildContext context) {
    if (!PlatformInfo.isIOS) {
      return Theme.of(context).colorScheme.surface;
    }
    return CupertinoTheme.of(context).scaffoldBackgroundColor;
  }
}

class _ModalSheetMediaQuery extends StatelessWidget {
  const _ModalSheetMediaQuery({
    required this.useSafeArea,
    required this.navigationBarTopPadding,
    required this.child,
  });

  final bool useSafeArea;
  final double navigationBarTopPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final sheetData = data.copyWith(
      padding: data.padding.copyWith(top: 0),
      viewPadding: data.viewPadding.copyWith(top: 0),
    );
    final safeAreaChild = useSafeArea
        ? SafeArea(top: false, child: child)
        : child;

    return MediaQuery(
      data: sheetData,
      child: AdaptiveModalSheetScope(
        navigationBarTopPadding: navigationBarTopPadding,
        child: safeAreaChild,
      ),
    );
  }
}

class _ModalSheetDragIndicator extends StatelessWidget {
  const _ModalSheetDragIndicator();

  @override
  Widget build(BuildContext context) {
    final color = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGrey3,
      context,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

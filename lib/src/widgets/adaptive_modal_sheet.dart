import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';

const Duration _modalSheetEnterDuration = Duration(milliseconds: 350);
const Duration _modalSheetExitDuration = Duration(milliseconds: 250);

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
  AnimationController? _animationController;

  @override
  Color get barrierColor => _barrierColor;

  @override
  String get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => _modalSheetEnterDuration;

  @override
  Duration get reverseTransitionDuration => _modalSheetExitDuration;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = BottomSheet.createAnimationController(
      navigator!.overlay!,
    );
    _animationController!.duration = transitionDuration;
    _animationController!.reverseDuration = reverseTransitionDuration;
    return _animationController!;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AdaptiveModalBottomSheet<T>(
          route: this,
          showDragIndicator: showDragIndicator,
          cornerRadius: cornerRadius,
          enableDrag: enableDrag,
          useSafeArea: useSafeArea,
          navigationBarTopPadding: navigationBarTopPadding,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  AdaptivePresentationDetent _largestDetent() {
    if (presentationDetents.contains(AdaptivePresentationDetent.large)) {
      return AdaptivePresentationDetent.large;
    }
    return AdaptivePresentationDetent.medium;
  }

  double _sheetHeight(MediaQueryData mediaQuery) {
    final topGap = _largestDetent() == AdaptivePresentationDetent.large
        ? 8.0
        : mediaQuery.size.height * 0.5;
    final topPadding = _largestDetent() == AdaptivePresentationDetent.large
        ? mediaQuery.viewPadding.top
        : 0.0;

    return (mediaQuery.size.height - topPadding - topGap)
        .clamp(0.0, mediaQuery.size.height)
        .toDouble();
  }
}

class _AdaptiveModalBottomSheet<T> extends StatefulWidget {
  const _AdaptiveModalBottomSheet({
    required this.route,
    required this.showDragIndicator,
    required this.cornerRadius,
    required this.enableDrag,
    required this.useSafeArea,
    required this.navigationBarTopPadding,
    required this.backgroundColor,
  });

  final _AdaptiveModalSheetRoute<T> route;
  final bool showDragIndicator;
  final double cornerRadius;
  final bool enableDrag;
  final bool useSafeArea;
  final double navigationBarTopPadding;
  final Color? backgroundColor;

  @override
  State<_AdaptiveModalBottomSheet<T>> createState() =>
      _AdaptiveModalBottomSheetState<T>();
}

class _AdaptiveModalBottomSheetState<T>
    extends State<_AdaptiveModalBottomSheet<T>> {
  static const double _dismissDistance = 96;
  static const double _dismissVelocity = 700;

  double? _dragStartDy;

  String _routeLabel(MaterialLocalizations localizations) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android ||
        platform == TargetPlatform.fuchsia) {
      return localizations.dialogLabel;
    }
    return '';
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStartDy = details.globalPosition.dy;
  }

  void _handleDragEnd(DragEndDetails details, {required bool isClosing}) {
    final dragStartDy = _dragStartDy;
    _dragStartDy = null;

    if (isClosing || dragStartDy == null || !widget.route.isCurrent) {
      return;
    }

    final dragDistance = details.globalPosition.dy - dragStartDy;
    final isDismissGesture =
        dragDistance >= _dismissDistance ||
        details.velocity.pixelsPerSecond.dy >= _dismissVelocity;

    if (isDismissGesture) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));

    final mediaQuery = MediaQuery.of(context);
    final localizations = MaterialLocalizations.of(context);
    final routeLabel = _routeLabel(localizations);

    return AnimatedBuilder(
      animation: widget.route.animation!,
      builder: (context, child) {
        final animationValue = mediaQuery.accessibleNavigation
            ? 1.0
            : widget.route.animation!.value;

        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: CustomSingleChildLayout(
              delegate: _AdaptiveModalSheetLayout(
                animationValue,
                widget.route._sheetHeight(mediaQuery),
              ),
              child: BottomSheet(
                animationController: widget.route._animationController,
                onClosing: () {
                  if (widget.route.isCurrent) {
                    Navigator.pop(context);
                  }
                },
                builder: (sheetContext) {
                  return _AdaptiveModalSheetContent(
                    showDragIndicator: widget.showDragIndicator,
                    cornerRadius: widget.cornerRadius,
                    useSafeArea: widget.useSafeArea,
                    navigationBarTopPadding: widget.navigationBarTopPadding,
                    backgroundColor: widget.backgroundColor,
                    child: widget.route.builder(sheetContext),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                enableDrag: widget.enableDrag,
                onDragStart: _handleDragStart,
                onDragEnd: _handleDragEnd,
                clipBehavior: Clip.none,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdaptiveModalSheetLayout extends SingleChildLayoutDelegate {
  const _AdaptiveModalSheetLayout(this.progress, this.maxHeight);

  final double progress;
  final double maxHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_AdaptiveModalSheetLayout oldDelegate) {
    return progress != oldDelegate.progress ||
        maxHeight != oldDelegate.maxHeight;
  }
}

class _AdaptiveModalSheetContent extends StatelessWidget {
  const _AdaptiveModalSheetContent({
    required this.showDragIndicator,
    required this.cornerRadius,
    required this.useSafeArea,
    required this.navigationBarTopPadding,
    required this.backgroundColor,
    required this.child,
  });

  final bool showDragIndicator;
  final double cornerRadius;
  final bool useSafeArea;
  final double navigationBarTopPadding;
  final Color? backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheetChild = _ModalSheetMediaQuery(
      useSafeArea: useSafeArea,
      navigationBarTopPadding: navigationBarTopPadding,
      child: child,
    );

    final content = showDragIndicator
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ModalSheetDragIndicator(),
              Flexible(fit: FlexFit.loose, child: sheetChild),
            ],
          )
        : sheetChild;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(cornerRadius)),
      child: Material(
        color: backgroundColor ?? _defaultBackgroundColor(context),
        child: content,
      ),
    );
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

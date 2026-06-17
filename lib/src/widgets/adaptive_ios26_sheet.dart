import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import 'adaptive_modal_sheet.dart';

const double _kIOS26SheetTopGapRatio = 0.065;
const double _kIOS26SheetCornerRadius = 34.0;
const Duration _kIOS26SheetTransitionDuration = Duration(milliseconds: 500);
const double _kIOS26SheetMinFlingVelocity = 2.0;
const Duration _kIOS26SheetDroppedDragAnimationDuration = Duration(
  milliseconds: 300,
);

/// Presents an iOS 26 styled sheet that keeps the route behavior of
/// [showCupertinoSheet] while tuning the shell for a more modern appearance.
class AdaptiveIOS26Sheet {
  AdaptiveIOS26Sheet._();

  /// Shows an iOS 26 styled sheet.
  ///
  /// This convenience API mirrors [showCupertinoSheet] for nested navigation,
  /// but uses a dedicated route and sheet chrome tuned for iOS 26 style.
  static Future<T?> show<T>({
    required BuildContext context,
    @Deprecated(
      'Use builder instead. '
      'This feature was deprecated after v3.33.0-0.2.pre.',
    )
    WidgetBuilder? pageBuilder,
    WidgetBuilder? builder,
    bool useNestedNavigation = false,
    bool enableDrag = true,
    double? topGap,
    bool showDragHandle = false,
    double cornerRadius = _kIOS26SheetCornerRadius,
    double navigationBarTopPadding = 10,
    Color? backgroundColor,
    RouteSettings? routeSettings,
  }) {
    assert(topGap == null || (topGap >= 0.0 && topGap <= 0.9));
    assert(pageBuilder != null || builder != null);

    final WidgetBuilder effectivePageBuilder = builder ?? pageBuilder!;
    final WidgetBuilder routeBuilder;
    final nestedNavigatorKey = GlobalKey<NavigatorState>();

    if (!useNestedNavigation) {
      routeBuilder = effectivePageBuilder;
    } else {
      routeBuilder = (BuildContext context) {
        return NavigatorPopHandler(
          onPopWithResult: (T? result) {
            nestedNavigatorKey.currentState!.maybePop();
          },
          child: Navigator(
            key: nestedNavigatorKey,
            initialRoute: '/',
            onGenerateInitialRoutes:
                (NavigatorState navigator, String initialRouteName) {
                  return <Route<void>>[
                    CupertinoPageRoute<void>(
                      builder: (BuildContext context) {
                        return PopScope(
                          canPop: false,
                          onPopInvokedWithResult:
                              (bool didPop, Object? result) {
                                if (didPop) {
                                  return;
                                }
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(result);
                              },
                          child: effectivePageBuilder(context),
                        );
                      },
                    ),
                  ];
                },
          ),
        );
      };
    }

    return Navigator.of(context, rootNavigator: true).push<T>(
      AdaptiveIOS26SheetRoute<T>(
        builder: routeBuilder,
        enableDrag: enableDrag,
        topGap: topGap,
        showDragHandle: showDragHandle,
        cornerRadius: cornerRadius,
        navigationBarTopPadding: navigationBarTopPadding,
        backgroundColor: backgroundColor,
        settings: routeSettings,
      ),
    );
  }
}

/// Route for displaying an iOS 26 styled sheet page.
class AdaptiveIOS26SheetRoute<T> extends PageRoute<T>
    with _AdaptiveIOS26SheetRouteTransitionMixin<T> {
  AdaptiveIOS26SheetRoute({
    super.settings,
    required this.builder,
    this.enableDrag = true,
    double? topGap,
    this.showDragHandle = false,
    this.cornerRadius = _kIOS26SheetCornerRadius,
    this.navigationBarTopPadding = 10,
    this.backgroundColor,
  }) : assert(
         topGap == null || (topGap >= 0.0 && topGap <= 0.9),
         'topGap must be between 0.0 and 0.9',
       ),
       _topGap = topGap;

  final WidgetBuilder builder;

  @override
  final bool enableDrag;

  final double? _topGap;

  @override
  double get topGap => _topGap ?? _kIOS26SheetTopGapRatio;

  @override
  bool get hasCustomTopGap => _topGap != null;

  final bool showDragHandle;
  final double cornerRadius;
  final double navigationBarTopPadding;
  final Color? backgroundColor;

  Widget _sheetWithHandle(BuildContext context) {
    if (!showDragHandle) {
      return builder(context);
    }

    const double dragHandleTopPadding = 11.0;
    const double dragHandleHeight = 5.0;
    const double dragHandleWidth = 40.0;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        builder(context),
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: dragHandleTopPadding),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(dragHandleWidth / 2),
                    ),
                  ),
                  color: CupertinoDynamicColor.withBrightness(
                    color: const Color(0x66777780),
                    darkColor: const Color(0x80F2F2F7),
                  ).resolveFrom(context),
                ),
                child: const SizedBox(
                  height: dragHandleHeight,
                  width: dragHandleWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final Color resolvedBackground =
        CupertinoDynamicColor.maybeResolve(backgroundColor, context) ??
        CupertinoDynamicColor.resolve(
          CupertinoDynamicColor.withBrightness(
            color: const Color(0xFFF7F7FB),
            darkColor: const Color(0xFF17171A),
          ),
          context,
        );
    final Color borderColor = CupertinoDynamicColor.resolve(
      CupertinoDynamicColor.withBrightness(
        color: const Color(0x40FFFFFF),
        darkColor: const Color(0x22FFFFFF),
      ),
      context,
    );
    final double effectiveNavigationBarTopPadding =
        navigationBarTopPadding + (showDragHandle ? 18 : 0);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: CupertinoDynamicColor.resolve(
                CupertinoDynamicColor.withBrightness(
                  color: const Color(0x33000000),
                  darkColor: const Color(0x55000000),
                ),
                context,
              ),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(cornerRadius),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resolvedBackground,
              border: Border.all(color: borderColor, width: 0.8),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(cornerRadius),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoDynamicColor.resolve(
                          CupertinoDynamicColor.withBrightness(
                            color: const Color(0x18FFFFFF),
                            darkColor: const Color(0x12FFFFFF),
                          ),
                          context,
                        ),
                        CupertinoColors.transparent,
                      ],
                    ),
                  ),
                ),
                CupertinoUserInterfaceLevel(
                  data: CupertinoUserInterfaceLevelData.elevated,
                  child: AdaptiveModalSheetScope(
                    navigationBarTopPadding: effectiveNavigationBarTopPadding,
                    child: _AdaptiveIOS26SheetScope(
                      child: _sheetWithHandle(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool hasParentSheet(BuildContext context) {
    return _AdaptiveIOS26SheetScope.maybeOf(context) != null;
  }

  static void popSheet(BuildContext context) {
    if (hasParentSheet(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Color? get barrierColor => CupertinoDynamicColor.withBrightness(
    color: const Color(0x14000000),
    darkColor: const Color(0x24000000),
  );

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;
}

class _AdaptiveIOS26SheetScope extends InheritedWidget {
  const _AdaptiveIOS26SheetScope({required super.child});

  static _AdaptiveIOS26SheetScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_AdaptiveIOS26SheetScope>();
  }

  @override
  bool updateShouldNotify(_AdaptiveIOS26SheetScope oldWidget) => false;
}

mixin _AdaptiveIOS26SheetRouteTransitionMixin<T> on PageRoute<T> {
  @protected
  Widget buildContent(BuildContext context);

  bool get enableDrag;
  double get topGap;
  bool get hasCustomTopGap;

  @override
  Duration get transitionDuration => _kIOS26SheetTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return buildContent(context);
  }

  static _AdaptiveIOS26SheetDragGestureController<T> _startPopGesture<T>(
    ModalRoute<T> route,
    double topGap,
  ) {
    return _AdaptiveIOS26SheetDragGestureController<T>(
      topGap: topGap,
      navigator: route.navigator!,
      getIsCurrent: () => route.isCurrent,
      getIsActive: () => route.isActive,
      popDragController: route.controller!,
    );
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return !hasCustomTopGap;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (hasCustomTopGap) {
      return false;
    }
    return nextRoute is AdaptiveIOS26SheetRoute<dynamic> ||
        nextRoute is CupertinoSheetRoute<dynamic>;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool linearTransition = popGestureInProgress;
    return CupertinoSheetTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linearTransition,
      topGap: topGap,
      child: _AdaptiveIOS26SheetDragGestureDetector<T>(
        enabledCallback: () => enableDrag,
        onStartPopGesture: () => _startPopGesture<T>(this, topGap),
        child: child,
      ),
    );
  }
}

class _AdaptiveIOS26SheetDragGestureDetector<T> extends StatefulWidget {
  const _AdaptiveIOS26SheetDragGestureDetector({
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<_AdaptiveIOS26SheetDragGestureController<T>>
  onStartPopGesture;

  @override
  State<_AdaptiveIOS26SheetDragGestureDetector<T>> createState() =>
      _AdaptiveIOS26SheetDragGestureDetectorState<T>();
}

class _AdaptiveIOS26SheetDragGestureDetectorState<T>
    extends State<_AdaptiveIOS26SheetDragGestureDetector<T>> {
  _AdaptiveIOS26SheetDragGestureController<T>? _dragGestureController;
  late VerticalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    if (_dragGestureController != null) {
      _dragGestureController!._stopUserGesture();
      _dragGestureController = null;
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_dragGestureController == null);
    _dragGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_dragGestureController != null);
    _dragGestureController!.dragUpdate(details.primaryDelta!);
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_dragGestureController != null);
    _dragGestureController!.dragEnd(
      details.velocity.pixelsPerSecond.dy / context.size!.height,
    );
    _dragGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _dragGestureController?.dragEnd(0.0);
    _dragGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

class _AdaptiveIOS26SheetDragGestureController<T> {
  _AdaptiveIOS26SheetDragGestureController({
    required this.navigator,
    required this.popDragController,
    required this.getIsActive,
    required this.getIsCurrent,
    required this.topGap,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController popDragController;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final double topGap;
  bool _didStopUserGesture = false;

  void _stopUserGesture() {
    if (_didStopUserGesture) {
      return;
    }
    _didStopUserGesture = true;
    if (navigator.mounted) {
      navigator.didStopUserGesture();
    }
  }

  void dragUpdate(double delta) {
    popDragController.value -=
        delta /
        (navigator.context.size!.height -
            (navigator.context.size!.height * topGap));
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.easeOut;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;
    TickerFuture? pendingAnimation;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kIOS26SheetMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = popDragController.value > 0.52;
    }

    if (animateForward) {
      pendingAnimation = popDragController.animateTo(
        1.0,
        duration: _kIOS26SheetDroppedDragAnimationDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        navigator.pop();
      }

      if (!popDragController.isDismissed) {
        pendingAnimation = popDragController.animateBack(
          0.0,
          duration: _kIOS26SheetDroppedDragAnimationDuration,
          curve: animationCurve,
        );
      }
    }

    if (pendingAnimation != null) {
      pendingAnimation.whenCompleteOrCancel(_stopUserGesture);
    } else {
      _stopUserGesture();
    }
  }
}

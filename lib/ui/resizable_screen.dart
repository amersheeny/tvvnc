import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'viewer.dart';
import 'copy.dart';
import 'widgets.dart';

/// Local layout state, separate from transport snapshots and TV input.
class ResizableScreen extends StatefulWidget {
  const ResizableScreen({
    super.key,
    required this.model,
    required this.height,
    required this.defaultViewerHeight,
    required this.maximumHeight,
    required this.availableHeight,
    this.direct = false,
  });
  final TvModel model;
  final ValueNotifier<double?> height;
  final double defaultViewerHeight;
  final double maximumHeight;
  final double availableHeight;
  final bool direct;

  @override
  State<ResizableScreen> createState() => _ResizableScreenState();
}

class _ResizableScreenState extends State<ResizableScreen>
    with WidgetsBindingObserver {
  final handleFocus = FocusNode();
  final viewerKey = GlobalKey<ScreenViewerState>();
  double? startY;
  double? startHeight;
  bool focused = false;
  bool menuOpen = false;
  double? menuHeight;
  (String?, int?, int)? identity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void cancelDrag() {
    startY = null;
    startHeight = null;
  }

  @override
  void didChangeMetrics() => cancelDrag();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) cancelDrag();
  }

  @override
  void didUpdateWidget(ResizableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maximumHeight != oldWidget.maximumHeight ||
        widget.availableHeight != oldWidget.availableHeight ||
        widget.direct != oldWidget.direct) {
      cancelDrag();
    }
  }

  @override
  void dispose() {
    cancelDrag();
    WidgetsBinding.instance.removeObserver(this);
    handleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ScreenInfo>(
    valueListenable: widget.model.screen,
    builder: (context, frame, _) {
      final nextIdentity = (
        widget.model.target?.deviceId,
        widget.model.target?.sessionId,
        frame.generation,
      );
      if (identity != nextIdentity || frame.hidden == true) cancelDrag();
      identity = nextIdentity;
      return LayoutBuilder(
        builder: (context, box) {
          final colors = Theme.of(context).colorScheme;
          const band = 8.0;
          final compact =
              menuOpen || (widget.maximumHeight < 96 && box.maxWidth < 8 * 48);
          final requiredMinimum = compact ? 80.0 : 96.0;
          // 8 dp grip strip + the existing 48 dp toolbar. The gesture target
          // lives in this chrome, never over interactive television pixels.
          final maximum = math.max(
            56.0,
            math.min(
              widget.availableHeight,
              math.max(widget.maximumHeight, requiredMinimum),
            ),
          );
          final minimum = math.min(maximum, requiredMinimum);
          return ValueListenableBuilder<double?>(
            valueListenable: widget.height,
            builder: (context, preference, _) {
              final effective = frame.hidden == true
                  ? 48.0
                  : (menuOpen
                            ? menuHeight!
                            : preference ?? widget.defaultViewerHeight + band)
                        .clamp(minimum, maximum)
                        .toDouble();
              void resize(double next) {
                viewerKey.currentState?.cancelPointerInput();
                final resized = next.clamp(minimum, maximum).toDouble();
                if (resized != effective) {
                  viewerKey.currentState?.fitMode = true;
                  widget.height.value = resized;
                }
              }

              final step = math.max(16.0, widget.availableHeight / 100);
              String value(double height) => Copy.format('screenHeightValue', {
                'percent': widget.availableHeight <= 0
                    ? '0'
                    : (100 * height / widget.availableHeight)
                          .round()
                          .toString(),
              });
              Widget resizeChrome(Widget controls) => Listener(
                onPointerDown: (_) =>
                    viewerKey.currentState?.cancelPointerInput(),
                child: Focus(
                  focusNode: handleFocus,
                  onFocusChange: (value) => setState(() => focused = value),
                  onKeyEvent: (_, event) {
                    if (!handleFocus.hasPrimaryFocus || minimum == maximum) {
                      return KeyEventResult.ignored;
                    }
                    final key = event.logicalKey;
                    if (key != LogicalKeyboardKey.arrowUp &&
                        key != LogicalKeyboardKey.arrowDown) {
                      return KeyEventResult.ignored;
                    }
                    if (event is KeyDownEvent || event is KeyRepeatEvent) {
                      resize(
                        effective +
                            (key == LogicalKeyboardKey.arrowDown
                                ? step
                                : -step),
                      );
                    }
                    return KeyEventResult.handled;
                  },
                  child: Semantics(
                    key: const ValueKey('screen-resize-handle'),
                    container: true,
                    explicitChildNodes: true,
                    slider: true,
                    label: t('screenSize'),
                    value: value(effective),
                    increasedValue: value(
                      (effective + step).clamp(minimum, maximum),
                    ),
                    decreasedValue: value(
                      (effective - step).clamp(minimum, maximum),
                    ),
                    onIncrease: effective < maximum
                        ? () => resize(effective + step)
                        : null,
                    onDecrease: effective > minimum
                        ? () => resize(effective - step)
                        : null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onVerticalDragStart: minimum == maximum
                          ? null
                          : (event) {
                              startY = event.globalPosition.dy;
                              startHeight = effective;
                            },
                      onVerticalDragUpdate: minimum == maximum
                          ? null
                          : (event) {
                              if (startY != null && startHeight != null) {
                                resize(
                                  startHeight! +
                                      event.globalPosition.dy -
                                      startY!,
                                );
                              }
                            },
                      onVerticalDragEnd: minimum == maximum
                          ? null
                          : (_) => cancelDrag(),
                      onVerticalDragCancel: minimum == maximum
                          ? null
                          : cancelDrag,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: band,
                            child: Center(
                              child: Container(
                                key: const ValueKey('screen-resize-grip'),
                                width: 48,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: focused && handleFocus.hasPrimaryFocus
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          controls,
                        ],
                      ),
                    ),
                  ),
                ),
              );
              final compactControls = SizedBox(
                key: const ValueKey('viewer-toolbar'),
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 48,
                    child: PopupMenuButton<IconButton>(
                      tooltip: t('screenControls'),
                      icon: const Icon(Icons.more_horiz),
                      onOpened: () {
                        viewerKey.currentState?.cancelPointerInput();
                        setState(() {
                          menuHeight = effective;
                          menuOpen = true;
                        });
                      },
                      onCanceled: () {
                        if (mounted) {
                          setState(() {
                            menuOpen = false;
                            menuHeight = null;
                          });
                        }
                      },
                      onSelected: (button) {
                        setState(() {
                          menuOpen = false;
                          menuHeight = null;
                        });
                        button.onPressed?.call();
                      },
                      itemBuilder: (_) => [
                        for (final button
                            in viewerKey.currentState?.controlButtons(
                                  widget.model.screen.value,
                                ) ??
                                <IconButton>[])
                          PopupMenuItem<IconButton>(
                            value: button,
                            enabled: button.onPressed != null,
                            child: Row(
                              children: [
                                button.icon,
                                const SizedBox(width: 12),
                                Flexible(child: Text(button.tooltip!)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
              return SizedBox(
                key: const ValueKey('resizable-screen'),
                height: effective,
                child: ScreenViewer(
                  key: viewerKey,
                  model: widget.model,
                  direct: widget.direct,
                  toolbarBuilder: (toolbar) =>
                      resizeChrome(compact ? compactControls : toolbar),
                ),
              );
            },
          );
        },
      );
    },
  );
}

/// Uses the rendered block, including wrapping and text scaling, not estimates.
class MeasuredSize extends StatefulWidget {
  const MeasuredSize({super.key, required this.onChange, required this.child});
  final ValueChanged<Size> onChange;
  final Widget child;
  @override
  State<MeasuredSize> createState() => _MeasuredSizeState();
}

class _MeasuredSizeState extends State<MeasuredSize> {
  final sizeKey = GlobalKey();
  Size? last;
  bool scheduled = false;
  void measure() {
    if (scheduled) return;
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      if (!mounted) return;
      final size = sizeKey.currentContext?.size;
      if (size != null && size != last) {
        last = size;
        widget.onChange(size);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    measure();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          measure();
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: SizedBox(key: sizeKey, child: widget.child),
        ),
      );
}

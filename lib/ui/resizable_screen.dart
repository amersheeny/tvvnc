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
          final style = DefaultTextStyle.of(context).style.merge(
            Theme.of(context).textTheme.labelMedium!.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: MediaQuery.boldTextOf(context)
                  ? FontWeight.bold
                  : null,
            ),
          );
          double measureBand(String caption, double menuWidth) {
            final label = TextPainter(
              text: TextSpan(text: caption, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              locale: Localizations.maybeLocaleOf(context),
            )..layout(maxWidth: math.max(1, box.maxWidth - 56 - menuWidth));
            final result = math.max(48.0, label.height + 16);
            label.dispose();
            return result;
          }

          final normalBand = measureBand(t('resizeScreen'), 0);
          final compact = menuOpen || widget.maximumHeight < normalBand + 72;
          final caption = t(compact ? 'screenSize' : 'resizeScreen');
          final band = compact ? measureBand(caption, 48) : normalBand;
          final requiredMinimum = band + (compact ? 24 : 72);
          // The controls' reserve is soft; the visible resize band is not. Tiny
          // pages use their outer scrolling fallback, never an inner clipped band.
          final maximum = math.max(
            band,
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
                if (resized != effective) widget.height.value = resized;
              }

              final step = math.max(16.0, widget.availableHeight / 100);
              String value(double height) => Copy.format('screenHeightValue', {
                'percent': widget.availableHeight <= 0
                    ? '0'
                    : (100 * height / widget.availableHeight)
                          .round()
                          .toString(),
              });
              final handle = Focus(
                focusNode: handleFocus,
                onFocusChange: (value) => setState(() => focused = value),
                onKeyEvent: (_, event) {
                  final key = event.logicalKey;
                  if (key != LogicalKeyboardKey.arrowUp &&
                      key != LogicalKeyboardKey.arrowDown) {
                    return KeyEventResult.ignored;
                  }
                  if (event is KeyDownEvent || event is KeyRepeatEvent) {
                    resize(
                      effective +
                          (key == LogicalKeyboardKey.arrowDown ? step : -step),
                    );
                  }
                  return KeyEventResult.handled;
                },
                child: Semantics(
                  key: const ValueKey('screen-resize-handle'),
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
                    onVerticalDragStart: (event) {
                      startY = event.globalPosition.dy;
                      startHeight = effective;
                    },
                    onVerticalDragUpdate: (event) {
                      if (startY != null && startHeight != null) {
                        resize(
                          startHeight! + event.globalPosition.dy - startY!,
                        );
                      }
                    },
                    onVerticalDragEnd: (_) => cancelDrag(),
                    onVerticalDragCancel: cancelDrag,
                    child: ExcludeSemantics(
                      child: Tooltip(
                        message: t('resizeScreen'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.drag_handle,
                                size: 24,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(caption, style: style)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              final bar = Listener(
                onPointerDown: (_) =>
                    viewerKey.currentState?.cancelPointerInput(),
                child: Container(
                  height: band,
                  color: colors.surfaceContainer,
                  foregroundDecoration: BoxDecoration(
                    border: Border.all(
                      color: focused ? colors.primary : colors.outlineVariant,
                      width: focused ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: handle),
                      if (compact)
                        SizedBox(
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
                    ],
                  ),
                ),
              );
              return SizedBox(
                key: const ValueKey('resizable-screen'),
                height: effective,
                child: Column(
                  children: [
                    Expanded(
                      child: ScreenViewer(
                        key: viewerKey,
                        model: widget.model,
                        direct: widget.direct,
                        showToolbar: !compact,
                      ),
                    ),
                    if (frame.hidden != true) bar,
                  ],
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

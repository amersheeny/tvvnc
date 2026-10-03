import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import '../model/pointer_queue.dart';
import 'widgets.dart';

Offset? framebufferPoint(
  Offset position,
  TransformationController transform,
  int width,
  int height,
) {
  final point = transform.toScene(position);
  if (point.dx < 0 || point.dy < 0 || point.dx >= width || point.dy >= height) {
    return null;
  }
  return point;
}

class ScreenViewer extends StatefulWidget {
  const ScreenViewer({
    super.key,
    required this.model,
    this.direct = false,
    this.fullscreen = false,
    this.showToolbar = true,
    this.toolbarBuilder,
  });
  final TvModel model;
  final bool direct;
  final bool fullscreen;
  final bool showToolbar;
  final Widget Function(Widget)? toolbarBuilder;
  @override
  State<ScreenViewer> createState() => ScreenViewerState();
}

class ScreenViewerState extends State<ScreenViewer> {
  final transform = TransformationController();
  final pointers = <int>{};
  Size viewport = Size.zero;
  int generation = -1;
  Size frameSize = Size.zero;
  double fitScale = 1;
  bool fitMode = true;
  bool settingTransform = false;
  Size transformViewport = Size.zero;
  int geometryEpoch = 0;
  Size? windowSize;
  Offset? lastPoint;
  int? remotePointer;
  int? remoteGeneration;
  (int, Offset, Offset, int)? candidate;
  bool multiTouch = false;
  late final writes = PointerQueue(
    widget.model.api.pointer,
    (error) => widget.model.report(TvModel.errorKey(error)),
  );
  bool detailed = false;
  @override
  void initState() {
    super.initState();
    transform.addListener(detailChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextWindowSize = MediaQuery.sizeOf(context);
    if (windowSize != null && windowSize != nextWindowSize) fitMode = true;
    windowSize = nextWindowSize;
  }

  void detailChanged() {
    if (!settingTransform) {
      fitMode = false;
      transformViewport = viewport;
    }
    final next = transform.value.getMaxScaleOnAxis() > fitScale * 1.05;
    if (next == detailed) return;
    detailed = next;
    unawaited(
      widget.model.onTarget(
        (origin) => widget.model.api.screenDetail(
          origin.deviceId,
          origin.sessionId,
          detailed,
        ),
      ),
    );
  }

  void send(Offset point, int buttons, int epoch) {
    writes.send(point.dx.floor(), point.dy.floor(), buttons, epoch);
  }

  void release() {
    if (remotePointer != null &&
        lastPoint != null &&
        remoteGeneration != null) {
      send(lastPoint!, 0, remoteGeneration!);
    }
    remotePointer = null;
    remoteGeneration = null;
    candidate = null;
  }

  /// Cancel direct touch even at a size bound, where no viewport change follows.
  void cancelPointerInput() {
    release();
    pointers.clear();
    multiTouch = false;
  }

  void fit({bool actual = false}) {
    release();
    if (frameSize.isEmpty || viewport.isEmpty) return;
    fitMode = !actual;
    transformViewport = viewport;
    fitScale = math.min(
      viewport.width / frameSize.width,
      viewport.height / frameSize.height,
    );
    final scale = actual
        ? 1.0 / MediaQuery.devicePixelRatioOf(context)
        : fitScale;
    settingTransform = true;
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - frameSize.width * scale) / 2,
        (viewport.height - frameSize.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
    settingTransform = false;
  }

  void zoom(double factor) {
    release();
    final scale = transform.value.getMaxScaleOnAxis();
    final target = (scale * factor)
        .clamp(fitScale / 2, math.max(8.0, fitScale * 8))
        .toDouble();
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final scene = transform.toScene(center);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        center.dx - scene.dx * target,
        center.dy - scene.dy * target,
        0,
        1,
      )
      ..scaleByDouble(target, target, target, 1);
  }

  @override
  void didUpdateWidget(ScreenViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direct != widget.direct) release();
  }

  @override
  void dispose() {
    release();
    transform.removeListener(detailChanged);
    transform.dispose();
    super.dispose();
  }

  List<IconButton> controlButtons(ScreenInfo frame) => [
    IconButton(
      onPressed: () => fit(),
      tooltip: t('fit'),
      icon: const Icon(Icons.fit_screen),
    ),
    IconButton(
      onPressed: () => fit(actual: true),
      tooltip: t('actualSize'),
      icon: const Icon(Icons.crop_free),
    ),
    IconButton(
      onPressed: () => zoom(1.4),
      tooltip: t('zoomIn'),
      icon: const Icon(Icons.zoom_in),
    ),
    IconButton(
      onPressed: () => zoom(1 / 1.4),
      tooltip: t('zoomOut'),
      icon: const Icon(Icons.zoom_out),
    ),
    IconButton(
      onPressed: frame.stale
          ? null
          : () => widget.model.onTarget((origin) async {
              await widget.model.api.screenshot(
                origin.deviceId,
                origin.sessionId,
              );
              widget.model.report('screenshotSaved');
            }),
      tooltip: t('screenshot'),
      icon: const Icon(Icons.camera_alt_outlined),
    ),
    IconButton(
      onPressed: () => widget.model.onTarget(
        (origin) => widget.model.api.reconnectTransport(
          origin.deviceId,
          origin.sessionId,
          'vnc',
        ),
      ),
      tooltip: t('reconnect'),
      icon: const Icon(Icons.refresh),
    ),
    IconButton(
      onPressed: () => widget.model.onTarget((origin) async {
        if (frame.hidden == true) {
          await widget.model.api.startScreen(origin.deviceId, origin.sessionId);
        } else {
          await widget.model.api.stopScreen(origin.deviceId, origin.sessionId);
          if (widget.fullscreen && mounted) {
            Navigator.maybePop(context);
          }
        }
      }),
      tooltip: t(frame.hidden == true ? 'showScreen' : 'hideScreen'),
      icon: Icon(
        frame.hidden == true ? Icons.visibility : Icons.visibility_off_outlined,
      ),
    ),
    if (widget.fullscreen)
      IconButton(
        tooltip: t('remote'),
        icon: const Icon(Icons.settings_remote),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.model.selected?.name ?? t('remote')),
                  const SizedBox(height: 12),
                  Dpad(widget.model),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      RemoteButton(
                        model: widget.model,
                        code: 4,
                        label: t('back'),
                        icon: Icons.arrow_back,
                      ),
                      RemoteButton(
                        model: widget.model,
                        code: 3,
                        label: t('home'),
                        icon: Icons.home,
                      ),
                      RemoteButton(
                        model: widget.model,
                        code: 24,
                        label: t('volumeUp'),
                        icon: Icons.volume_up,
                      ),
                      RemoteButton(
                        model: widget.model,
                        code: 25,
                        label: t('volumeDown'),
                        icon: Icons.volume_down,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    if (!widget.fullscreen)
      IconButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(widget.model.selected?.name ?? t('screen')),
              ),
              body: SafeArea(
                child: ScreenViewer(
                  model: widget.model,
                  direct: widget.direct,
                  fullscreen: true,
                ),
              ),
            ),
          ),
        ),
        tooltip: t('fullScreen'),
        icon: const Icon(Icons.fullscreen),
      ),
  ];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ScreenInfo>(
    valueListenable: widget.model.screen,
    builder: (context, frame, _) => Column(
      children: [
        if (frame.hidden != true)
          Expanded(
            child: ClipRect(
              child: ColoredBox(
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final nextViewport = constraints.biggest;
                    final nextFrame = Size(
                      frame.width.toDouble(),
                      frame.height.toDouble(),
                    );
                    final viewportFit =
                        nextFrame.isEmpty || nextViewport.isEmpty
                        ? 1.0
                        : math.min(
                            nextViewport.width / nextFrame.width,
                            nextViewport.height / nextFrame.height,
                          );
                    if (generation != frame.generation ||
                        viewport != nextViewport ||
                        frameSize != nextFrame) {
                      final reset =
                          generation != frame.generation ||
                          frameSize != nextFrame;
                      final anchor = transform.toScene(
                        Offset(
                          transformViewport.width / 2,
                          transformViewport.height / 2,
                        ),
                      );
                      final scale = transform.value.getMaxScaleOnAxis();
                      final epoch = ++geometryEpoch;
                      release();
                      pointers.clear();
                      multiTouch = false;
                      generation = frame.generation;
                      viewport = nextViewport;
                      frameSize = nextFrame;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || epoch != geometryEpoch) return;
                        if (reset || fitMode || frameSize.isEmpty) {
                          fit();
                        } else {
                          fitScale = math.min(
                            viewport.width / frameSize.width,
                            viewport.height / frameSize.height,
                          );
                          transformViewport = viewport;
                          settingTransform = true;
                          transform.value = Matrix4.identity()
                            ..translateByDouble(
                              viewport.width / 2 - anchor.dx * scale,
                              viewport.height / 2 - anchor.dy * scale,
                              0,
                              1,
                            )
                            ..scaleByDouble(scale, scale, scale, 1);
                          settingTransform = false;
                        }
                      });
                    }
                    if (frame.stale) release();
                    final imageStatus = t(
                      frame.frameAt > 0 && frame.textureId != null
                          ? 'lastFrame'
                          : frame.connected && frame.textureId == null
                          ? 'screenHidden'
                          : 'screenUnavailable',
                    );
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (frame.textureId != null &&
                            frame.width > 0 &&
                            frame.height > 0)
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (event) {
                              pointers.add(event.pointer);
                              if (pointers.length > 1) {
                                multiTouch = true;
                                release();
                                setState(() {});
                                return;
                              }
                              if (widget.direct && !frame.stale) {
                                final point = framebufferPoint(
                                  event.localPosition,
                                  transform,
                                  frame.width,
                                  frame.height,
                                );
                                if (point != null) {
                                  candidate = (
                                    event.pointer,
                                    event.localPosition,
                                    point,
                                    frame.generation,
                                  );
                                }
                              }
                            },
                            onPointerMove: (event) {
                              final pending = candidate;
                              if (!multiTouch &&
                                  !frame.stale &&
                                  pending != null &&
                                  pending.$1 == event.pointer &&
                                  pending.$4 == frame.generation &&
                                  (event.localPosition - pending.$2).distance >
                                      kTouchSlop) {
                                remotePointer = pending.$1;
                                remoteGeneration = pending.$4;
                                lastPoint = pending.$3;
                                candidate = null;
                                send(pending.$3, 1, pending.$4);
                              }
                              if (event.pointer != remotePointer ||
                                  frame.stale) {
                                return;
                              }
                              final point = framebufferPoint(
                                event.localPosition,
                                transform,
                                frame.width,
                                frame.height,
                              );
                              if (point != null) {
                                lastPoint = point;
                                send(point, 1, frame.generation);
                              }
                            },
                            onPointerUp: (event) {
                              final pending = candidate;
                              if (!multiTouch &&
                                  !frame.stale &&
                                  pending != null &&
                                  pending.$1 == event.pointer &&
                                  pending.$4 == frame.generation) {
                                final end = framebufferPoint(
                                  event.localPosition,
                                  transform,
                                  frame.width,
                                  frame.height,
                                );
                                if (end != null) {
                                  send(pending.$3, 1, pending.$4);
                                  send(end, 0, pending.$4);
                                }
                                candidate = null;
                              }
                              if (event.pointer == remotePointer) release();
                              pointers.remove(event.pointer);
                              if (pointers.isEmpty) multiTouch = false;
                              if (mounted) setState(() {});
                            },
                            onPointerCancel: (event) {
                              release();
                              pointers.remove(event.pointer);
                              if (pointers.isEmpty) multiTouch = false;
                              if (mounted) setState(() {});
                            },
                            child: InteractiveViewer(
                              transformationController: transform,
                              constrained: false,
                              panEnabled: !widget.direct || pointers.length > 1,
                              scaleEnabled: true,
                              boundaryMargin: const EdgeInsets.all(
                                double.infinity,
                              ),
                              minScale: viewportFit / 2,
                              maxScale: math.max(8.0, viewportFit * 8),
                              child: SizedBox(
                                width: frame.width.toDouble(),
                                height: frame.height.toDouble(),
                                child: Semantics(
                                  label: frame.connected && !frame.stale
                                      ? t('liveScreen')
                                      : t('lastFrame'),
                                  image: true,
                                  child: Texture(
                                    textureId: frame.textureId!,
                                    filterQuality: FilterQuality.low,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (frame.textureId == null || frame.stale)
                          IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.65),
                              child: Center(
                                child: constraints.maxHeight < 80
                                    ? Icon(
                                        Icons.tv_off_outlined,
                                        color: Colors.white,
                                        size: math.min(
                                          24,
                                          constraints.maxHeight,
                                        ),
                                        semanticLabel: imageStatus,
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          imageStatus,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        if (widget.showToolbar || frame.hidden == true) viewingToolbar(frame),
      ],
    ),
  );

  Widget viewingToolbar(ScreenInfo frame) {
    final toolbar = SizedBox(
      key: const ValueKey('viewer-toolbar'),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: controlButtons(frame),
      ),
    );
    return frame.hidden == true
        ? toolbar
        : widget.toolbarBuilder?.call(toolbar) ?? toolbar;
  }
}

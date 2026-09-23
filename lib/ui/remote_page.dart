import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'resizable_screen.dart';
import 'widgets.dart';

const defaultLayout = [
  'back',
  'home',
  'options',
  'input',
  'guide',
  'info',
  'volumeUp',
  'channelUp',
  'volumeDown',
  'channelDown',
  'mute',
  'rewind',
  'playPause',
  'fastForward',
  'previous',
  'stop',
  'next',
];
const controls = <String, (int, IconData)>{
  'back': (4, Icons.arrow_back),
  'home': (3, Icons.home_outlined),
  'options': (82, Icons.more_horiz),
  'input': (178, Icons.input),
  'guide': (172, Icons.view_list_outlined),
  'info': (165, Icons.info_outline),
  'volumeUp': (24, Icons.volume_up_outlined),
  'volumeDown': (25, Icons.volume_down_outlined),
  'mute': (164, Icons.volume_off_outlined),
  'channelUp': (166, Icons.add),
  'channelDown': (167, Icons.remove),
  'rewind': (89, Icons.fast_rewind),
  'playPause': (85, Icons.play_circle_outline),
  'play': (126, Icons.play_arrow),
  'pause': (127, Icons.pause),
  'fastForward': (90, Icons.fast_forward),
  'previous': (88, Icons.skip_previous),
  'stop': (86, Icons.stop),
  'next': (87, Icons.skip_next),
  'enter': (66, Icons.keyboard_return),
  'backspace': (67, Icons.backspace_outlined),
  'delete': (112, Icons.delete_outline),
  'search': (84, Icons.search),
};

class VolumeSlider extends StatefulWidget {
  const VolumeSlider(this.model, {super.key});
  final TvModel model;
  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  double? draft;
  TvTarget? origin;
  String? volumeContext;
  @override
  Widget build(BuildContext context) {
    final s = widget.model.state;
    if (s?.volume == null ||
        s?.volumeMax == null ||
        s?.volumeMin == null ||
        s?.volumeContext == null) {
      return const SizedBox.shrink();
    }
    final maximum = s!.volumeMax!.toDouble();
    final minimum = s.volumeMin!.toDouble();
    if (maximum <= minimum) return const SizedBox.shrink();
    return Column(
      children: [
        Text(volumeLabel('${(draft ?? s.volume!).round()}', s.volumeTarget)),
        Slider(
          value: (draft ?? s.volume!.toDouble()).clamp(minimum, maximum),
          min: minimum,
          max: maximum,
          semanticFormatterCallback: (value) =>
              volumeLabel('${value.round()}', s.volumeTarget),
          onChangeStart: (_) {
            origin = widget.model.target;
            volumeContext = s.volumeContext;
          },
          onChanged: (value) => setState(() => draft = value),
          onChangeEnd: (value) async {
            await widget.model.command(
              CommandKind.volume,
              origin: origin,
              number: value.round(),
              value: volumeContext,
            );
            if (mounted) setState(() => draft = null);
          },
        ),
      ],
    );
  }
}

class RemotePage extends StatefulWidget {
  const RemotePage({
    super.key,
    required this.model,
    required this.onPage,
    this.mode = 'remote',
  });
  final TvModel model;
  final ValueChanged<String> onPage;
  final String mode;
  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  final screenKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final captured = m.target;
    final layout = m.selected?.layout.isNotEmpty == true
        ? m.selected!.layout
        : defaultLayout;
    final standardLayout = layout.join('|') == defaultLayout.join('|');
    final powerCapability = m.state?.capabilities
        .where((c) => c.id == 'powerToggle' && c.detail == 'tv')
        .firstOrNull;
    final powerControl = powerCapability == null
        ? null
        : IconButton.filledTonal(
            key: const ValueKey('tv-power'),
            tooltip: t('power'),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            onPressed: () => canTry(powerCapability.state)
                ? m.command(CommandKind.powerToggle, origin: captured)
                : explainControl(context, m, t('power')),
            icon: const Icon(Icons.power_settings_new),
          );
    Widget remoteControlsList({bool shrink = false}) {
      return ListView(
        shrinkWrap: shrink,
        physics: shrink ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(16),
        children: [
          if (m.state?.transports.any(
                (p) => p.id == 'remote' && p.state == Availability.needsSetup,
              ) ==
              true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Text(t('pairingRequired')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (captured != null) {
                        m.guard(() => m.api.pairRemote(captured.deviceId));
                      }
                    },
                    icon: const Icon(Icons.link),
                    label: Text(t('pairRemote')),
                  ),
                ],
              ),
            ),
          if (widget.mode == 'touchpad') Touchpad(m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (standardLayout)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final id in ['volumeUp', 'volumeDown', 'mute'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: RemoteButton(
                          model: m,
                          code: controls[id]!.$1,
                          label: t(id),
                          icon: controls[id]!.$2,
                          compact: true,
                        ),
                      ),
                  ],
                )
              else
                const SizedBox(width: 56),
              Flexible(child: Dpad(m)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (powerControl != null) ...[
                    powerControl,
                    const SizedBox(height: 6),
                  ],
                  IconButton.filledTonal(
                    tooltip: t('keyboard'),
                    constraints: const BoxConstraints(
                      minHeight: 56,
                      minWidth: 56,
                    ),
                    onPressed: () => widget.onPage('keyboard'),
                    icon: const Icon(Icons.keyboard_outlined),
                  ),
                  const SizedBox(height: 6),
                  VoiceButton(m, compact: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              Widget button(String id, double width) {
                final control = controls[id];
                if (control != null) {
                  return SizedBox(
                    width: width,
                    child: RemoteButton(
                      model: m,
                      code: control.$1,
                      label: t(id),
                      icon: control.$2,
                    ),
                  );
                }
                final found = m.state?.buttons
                    .where((b) => b.id == id)
                    .firstOrNull;
                if (found == null) return const SizedBox.shrink();
                if (found.androidCode != null) {
                  return SizedBox(
                    width: width,
                    child: RemoteButton(
                      model: m,
                      code: found.androidCode!,
                      label: t(found.name),
                      icon: Icons.radio_button_unchecked,
                    ),
                  );
                }
                return SizedBox(
                  width: width,
                  child: availabilityHint(
                    found.state,
                    ActionTile(
                      found.name,
                      Icons.radio_button_unchecked,
                      () => canTry(found.state)
                          ? m.command(
                              CommandKind.sony,
                              origin: captured,
                              value: id,
                            )
                          : explainControl(context, m, found.name),
                    ),
                  ),
                );
              }

              if (standardLayout) {
                const rows = [
                  ['back', 'home'],
                  ['options', 'input'],
                  ['guide', 'info'],
                  ['channelUp', 'channelDown'],
                  ['rewind', 'playPause', 'fastForward'],
                  ['previous', 'stop', 'next'],
                ];
                return Column(
                  children: [
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var index = 0;
                                index < row.length;
                                index++
                              ) ...[
                                if (index != 0) const SizedBox(width: 8),
                                button(
                                  row[index],
                                  row.length == 1
                                      ? (constraints.maxWidth - 8) / 2
                                      : (constraints.maxWidth -
                                                (row.length - 1) * 8) /
                                            row.length,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: layout.map((id) => button(id, width)).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          if (m.state?.volume != null &&
              m.state?.volumeMax != null &&
              m.state?.capabilities.any(
                    (c) =>
                        c.id == 'absoluteVolume' &&
                        (c.state == Availability.advertised ||
                            c.state == Availability.ready),
                  ) ==
                  true)
            VolumeSlider(m),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => widget.onPage('inputs'),
                icon: const Icon(Icons.input),
                label: Text(t('inputs')),
              ),
              TextButton.icon(
                onPressed: () => widget.onPage('apps'),
                icon: const Icon(Icons.apps),
                label: Text(t('apps')),
              ),
              TextButton.icon(
                onPressed: () => widget.onPage('allButtons'),
                icon: const Icon(Icons.dialpad),
                label: Text(t('allButtons')),
              ),
            ],
          ),
        ],
      );
    }

    final content = ValueListenableBuilder<ScreenInfo>(
      valueListenable: m.screen,
      builder: (context, frame, _) => LayoutBuilder(
        builder: (context, box) {
          final wide =
              box.maxWidth > 760 && box.maxHeight >= 56 && frame.hidden != true;
          final short = !wide && box.maxHeight < 192;
          final remote = remoteControlsList(shrink: short);
          final preview = ResizableScreen(
            key: screenKey,
            model: m,
            direct: widget.mode == 'directTouch',
            height: m.remoteScreenHeight,
            availableHeight: box.maxHeight,
            defaultViewerHeight: wide
                ? box.maxHeight - 48
                : (box.maxHeight * 0.3).clamp(150, 270),
            maximumHeight: wide
                ? box.maxHeight
                : math.max(box.maxHeight * .35, box.maxHeight - 192),
          );
          if (wide) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Align(alignment: Alignment.topCenter, child: preview),
                ),
                Expanded(flex: 2, child: remote),
              ],
            );
          }
          if (short) {
            return SingleChildScrollView(
              child: Column(children: [preview, remote]),
            );
          }
          return Column(
            children: [
              preview,
              Expanded(child: remote),
            ],
          );
        },
      ),
    );
    return content;
  }
}

class Touchpad extends StatefulWidget {
  const Touchpad(this.model, {super.key});
  final TvModel model;
  @override
  State<Touchpad> createState() => _TouchpadState();
}

class _TouchpadState extends State<Touchpad> {
  Offset accumulated = Offset.zero;
  TvTarget? origin;
  String? press;
  int? pointer;
  void endHold() {
    if (press != null && origin != null) {
      unawaited(
        widget.model.command(
          CommandKind.keyUp,
          origin: origin,
          code: 23,
          pressId: press,
        ),
      );
    }
    press = null;
  }

  @override
  void dispose() {
    endHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Semantics(
        label: t('touchpad'),
        button: true,
        onTap: () => widget.model.command(CommandKind.key, code: 23),
        child: Listener(
          onPointerDown: (event) {
            if (pointer == null) {
              pointer = event.pointer;
              origin = widget.model.target;
            }
          },
          onPointerUp: (event) {
            if (pointer == event.pointer) pointer = null;
          },
          onPointerCancel: (event) {
            if (pointer == event.pointer) {
              endHold();
              pointer = null;
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (origin == null) {
                widget.model.report('notSent');
                return;
              }
              widget.model.command(CommandKind.key, origin: origin, code: 23);
            },
            onPanStart: (_) {
              accumulated = Offset.zero;
            },
            onPanUpdate: (event) {
              if (origin == null) return;
              accumulated += event.delta;
              if (accumulated.distance < 42) return;
              final code = accumulated.dx.abs() > accumulated.dy.abs()
                  ? (accumulated.dx < 0 ? 21 : 22)
                  : (accumulated.dy < 0 ? 19 : 20);
              accumulated = Offset.zero;
              unawaited(
                widget.model.command(
                  CommandKind.key,
                  origin: origin,
                  code: code,
                ),
              );
            },
            onLongPressStart: (_) {
              if (origin == null) {
                widget.model.report('notSent');
                return;
              }
              if (widget.model.state?.buttons.any(
                    (button) => button.androidCode == 23 && button.canHold,
                  ) !=
                  true) {
                widget.model.report('holdUnavailable');
                return;
              }
              press = 'touchpad-${DateTime.now().microsecondsSinceEpoch}';
              unawaited(
                widget.model.command(
                  CommandKind.keyDown,
                  origin: origin,
                  code: 23,
                  pressId: press,
                ),
              );
            },
            onLongPressEnd: (_) => endHold(),
            onLongPressCancel: endHold,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swipe, size: 36),
                    const SizedBox(height: 8),
                    Text(t('touchpadHelp'), textAlign: TextAlign.center),
                    if (widget.model.state?.buttons.any(
                          (b) => b.androidCode == 23 && b.canHold,
                        ) ==
                        true)
                      Text(t('touchpadHold'), textAlign: TextAlign.center),
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

class VoiceButton extends StatefulWidget {
  const VoiceButton(this.model, {super.key, this.compact = false});
  final TvModel model;
  final bool compact;
  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  TvTarget? origin;
  TvTarget? gestureTarget;
  Availability get available =>
      widget.model.state?.capabilities
          .where((cap) => cap.id == 'voice')
          .firstOrNull
          ?.state ??
      Availability.unknown;
  void start({TvTarget? captured}) {
    if (available == Availability.unsupported) {
      widget.model.report('unsupported');
      return;
    }
    if (!canTry(available)) {
      explainControl(context, widget.model, t('voice'));
      return;
    }
    origin = captured ?? widget.model.target;
    final target = origin;
    if (target != null) {
      unawaited(
        widget.model.guard(
          () => widget.model.api.startVoice(target.deviceId, target.sessionId),
          origin: target,
        ),
      );
    }
  }

  void stop({TvTarget? explicitTarget}) {
    final target = origin ?? explicitTarget;
    origin = null;
    if (target != null) {
      unawaited(
        widget.model.guard(
          () => widget.model.api.stopVoice(target.deviceId, target.sessionId),
          origin: target,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (origin != null) stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.model.state?.voiceState ?? 'idle';
    final listening = state == 'listening' || state == 'starting';
    return availabilityHint(
      listening ? Availability.ready : available,
      Tooltip(
        message: t(listening ? 'stopVoice' : 'holdToSpeak'),
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          label: t('voice'),
          value: t(
            state == 'starting'
                ? 'voiceStarting'
                : state == 'listening'
                ? 'listening'
                : 'holdToSpeak',
          ),
          excludeSemantics: true,
          onTap: () =>
              listening ? stop(explicitTarget: widget.model.target) : start(),
          customSemanticsActions: {
            CustomSemanticsAction(label: t('startVoice')): () => start(),
            CustomSemanticsAction(label: t('stopVoice')): () =>
                stop(explicitTarget: widget.model.target),
          },
          child: Listener(
            onPointerCancel: (_) => stop(),
            child: GestureDetector(
              onLongPressDown: (_) => gestureTarget = widget.model.target,
              onLongPressStart: (_) {
                if (gestureTarget == null) {
                  widget.model.report('notSent');
                  return;
                }
                start(captured: gestureTarget);
              },
              onLongPressEnd: (_) => stop(),
              onLongPressCancel: () => stop(),
              child: FilledButton.tonal(
                onPressed: () => listening
                    ? stop(explicitTarget: widget.model.target)
                    : available == Availability.unsupported
                    ? widget.model.report('unsupported')
                    : canTry(available)
                    ? widget.model.report('holdToSpeak')
                    : explainControl(context, widget.model, t('voice')),
                style: FilledButton.styleFrom(
                  minimumSize: Size(56, widget.compact ? 56 : 72),
                  padding: const EdgeInsets.all(12),
                ),
                child: widget.compact
                    ? Icon(listening ? Icons.mic : Icons.mic_none)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(listening ? Icons.mic : Icons.mic_none),
                          const SizedBox(height: 4),
                          Text(
                            t(
                              state == 'listening'
                                  ? 'listening'
                                  : state == 'starting'
                                  ? 'voiceStarting'
                                  : 'holdToSpeak',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

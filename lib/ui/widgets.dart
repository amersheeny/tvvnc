import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'copy.dart';

String t(String key) => Copy.text(key);
String volumeLabel(String level, String? target) {
  final output = switch (target) {
    'speaker' => t('audioSpeakers'),
    'headphone' => t('audioHeadphones'),
    final name => name,
  };
  return output == null
      ? '${t('volume')}: $level'
      : Copy.format('volumeForOutput', {'output': output, 'level': level});
}

String availability(Availability status) => t(switch (status) {
  Availability.advertised => 'advertised',
  Availability.needsSetup => 'needsSetup',
  Availability.permissionRequired => 'permissionRequired',
  Availability.ready => 'ready',
  Availability.unavailable => 'unavailable',
  Availability.unsupported => 'unsupported',
  Availability.unknown => 'unknown',
});
bool canTry(Availability state) =>
    state == Availability.ready ||
    state == Availability.advertised ||
    state == Availability.unknown;

Widget availabilityHint(Availability state, Widget child) => Semantics(
  hint: canTry(state) ? null : availability(state),
  child: canTry(state)
      ? child
      : Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final colors = theme.colorScheme;
            return Stack(
              fit: StackFit.passthrough,
              children: [
                Theme(
                  data: theme.copyWith(
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        backgroundColor: colors.surfaceContainerHighest,
                        side: BorderSide(color: colors.outline),
                      ),
                    ),
                    outlinedButtonTheme: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: colors.outline),
                      ),
                    ),
                  ),
                  child: child,
                ),
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
);

Future<void> explainControl(BuildContext context, TvModel model, String label) {
  final target = model.target;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('controlUnavailable')),
            for (final transport
                in model.state?.transports ?? <TransportInfo>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t(
                    transport.id == 'remote'
                        ? 'androidRemote'
                        : transport.id == 'sony'
                        ? 'sonyApi'
                        : 'vnc',
                  ),
                ),
                subtitle: Text(
                  transport.errorCode == null
                      ? availability(transport.state)
                      : t(TvModel.codeKey(transport.errorCode)),
                ),
                trailing: IconButton(
                  tooltip: t('reconnect'),
                  icon: const Icon(Icons.refresh),
                  onPressed: target == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          model.guard(
                            () => model.api.reconnectTransport(
                              target.deviceId,
                              target.sessionId,
                              transport.id,
                            ),
                          );
                        },
                ),
              ),
            if (model.state?.transports.any(
                  (p) => p.id == 'remote' && p.state == Availability.needsSetup,
                ) ==
                true)
              TextButton(
                onPressed: target == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        model.guard(
                          () => model.api.pairRemote(target.deviceId),
                        );
                      },
                child: Text(t('pairRemote')),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('cancel')),
        ),
      ],
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String body,
  String action, {
  String? extraBody,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(title)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(body)),
              if (extraBody != null) ...[
                const SizedBox(height: 12),
                Text(t(extraBody)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t(action)),
          ),
        ],
      ),
    ) ??
    false;

class NetworkPermissionPanel extends StatelessWidget {
  const NetworkPermissionPanel(this.model, {super.key});
  final TvModel model;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t('permissionBody')),
        TextButton(
          onPressed: () => model.guard(model.api.openSettings),
          child: Text(t('openSettings')),
        ),
      ],
    ),
  );
}

class ActionTile extends StatelessWidget {
  const ActionTile(
    this.label,
    this.icon,
    this.onPressed, {
    super.key,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

/// Holds keep their original target even when the screen is rebuilt or disposed.
class RemoteButton extends StatefulWidget {
  const RemoteButton({
    super.key,
    required this.model,
    required this.code,
    required this.label,
    required this.icon,
    this.compact = false,
    this.beforePress,
    this.onDispatch,
  });
  final TvModel model;
  final int code;
  final String label;
  final IconData icon;
  final bool compact;
  final Future<bool> Function()? beforePress;
  final VoidCallback? onDispatch;
  @override
  State<RemoteButton> createState() => _RemoteButtonState();
}

class _RemoteButtonState extends State<RemoteButton> {
  TvTarget? origin;
  String? press;
  bool pointerHeld = false;
  bool pointerOriginCaptured = false;
  bool disposing = false;
  bool get canHold =>
      widget.model.state?.buttons.any(
        (b) => b.androidCode == widget.code && b.canHold,
      ) ==
      true;
  Future<void> start(TvTarget? captured) async {
    if (press != null) return;
    if (!canHold) {
      widget.model.report('holdUnavailable');
      return;
    }
    origin = captured;
    if (origin == null) return;
    press = '${DateTime.now().microsecondsSinceEpoch}-${widget.code}';
    final held = press;
    if (widget.beforePress != null && !await widget.beforePress!()) {
      if (press == held) release();
      return;
    }
    if (!mounted || disposing || press != held) return;
    widget.onDispatch?.call();
    unawaited(
      widget.model.command(
        CommandKind.keyDown,
        origin: origin,
        code: widget.code,
        pressId: press,
      ),
    );
    if (mounted && !disposing) setState(() {});
  }

  void release() {
    final held = press;
    final captured = origin;
    press = null;
    origin = null;
    pointerOriginCaptured = false;
    if (held != null && captured != null) {
      unawaited(
        widget.model.command(
          CommandKind.keyUp,
          origin: captured,
          code: widget.code,
          pressId: held,
        ),
      );
      if (mounted && !disposing) setState(() {});
    }
  }

  @override
  void dispose() {
    disposing = true;
    release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captured = widget.model.target;
    final state =
        widget.model.state?.buttons
            .where((b) => b.androidCode == widget.code)
            .firstOrNull
            ?.state ??
        Availability.unknown;
    final available = canTry(state);
    return Semantics(
      identifier: 'tv-key-${widget.code}',
      label: widget.label,
      button: true,
      customSemanticsActions: canHold
          ? {
              CustomSemanticsAction(label: t('hold')): () => start(captured),
              CustomSemanticsAction(label: t('release')): release,
            }
          : null,
      child: Listener(
        onPointerDown: (_) {
          if (press == null) {
            origin = captured;
            pointerOriginCaptured = true;
          }
          pointerHeld = false;
        },
        onPointerUp: (_) {
          if (pointerHeld) {
            release();
            scheduleMicrotask(() => pointerHeld = false);
          }
        },
        onPointerCancel: (_) {
          pointerHeld = false;
          pointerOriginCaptured = false;
          release();
        },
        child: Tooltip(
          message: widget.label,
          child: availabilityHint(
            state,
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 56),
                padding: EdgeInsets.all(widget.compact ? 12 : 10),
                backgroundColor: press != null
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              onPressed: () async {
                if (!available) {
                  explainControl(context, widget.model, widget.label);
                  return;
                }
                if (pointerHeld || press != null) {
                  release();
                  pointerHeld = false;
                  return;
                }
                final destination = pointerOriginCaptured ? origin : captured;
                pointerOriginCaptured = false;
                if (destination == null) {
                  widget.model.report('notSent');
                  return;
                }
                if (widget.beforePress != null &&
                    !await widget.beforePress!()) {
                  return;
                }
                if (!mounted || disposing) return;
                widget.onDispatch?.call();
                unawaited(
                  widget.model.command(
                    CommandKind.key,
                    origin: destination,
                    code: widget.code,
                  ),
                );
                origin = null;
              },
              onLongPress: () {
                pointerHeld = true;
                if (pointerOriginCaptured && origin == null) {
                  widget.model.report('notSent');
                  return;
                }
                start(origin ?? captured);
              },
              child: ExcludeSemantics(
                child: widget.compact
                    ? Icon(widget.icon)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon),
                          const SizedBox(height: 4),
                          Text(widget.label, textAlign: TextAlign.center),
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

class Dpad extends StatelessWidget {
  const Dpad(this.model, {super.key});
  final TvModel model;
  @override
  Widget build(BuildContext context) {
    Widget key(String name, int code, IconData icon) => RemoteButton(
      model: model,
      code: code,
      label: t(name),
      icon: icon,
      compact: true,
    );
    return Center(
      child: SizedBox(
        width: 192,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            key('up', 19, Icons.keyboard_arrow_up),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                key('left', 21, Icons.keyboard_arrow_left),
                key('ok', 23, Icons.radio_button_checked),
                key('right', 22, Icons.keyboard_arrow_right),
              ],
            ),
            const SizedBox(height: 6),
            key('down', 20, Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

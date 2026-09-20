import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'viewer.dart';
import 'widgets.dart';

class KeyboardPage extends StatefulWidget {
  const KeyboardPage(this.model, {super.key});
  final TvModel model;
  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage>
    with WidgetsBindingObserver {
  final text = TextEditingController();
  Timer? debounce;
  bool live = false;
  bool private = false;
  bool sensitiveDraft = false;
  bool get sensitive => private || sensitiveDraft;
  bool sending = false;
  TvTarget? origin;
  DraftContext? draftContext;
  bool composing = false;
  bool changingBuffer = false;
  int modeEpoch = 0;
  int bufferRevision = 0;
  int sendSequence = 0;
  int? activeSend;
  int? revision;
  int? lastEditorRevision;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.model.addListener(changed);
    origin = widget.model.target;
    draftContext = widget.model.draftContext;
    text.value = widget.model.draft(draftContext);
    text.addListener(compositionChanged);
    lastEditorRevision = widget.model.state?.editor?.revision;
  }

  void compositionChanged() {
    bufferRevision++;
    final next = !text.value.composing.isCollapsed;
    final committed = composing && !next;
    composing = next;
    if (!changingBuffer && !private && sensitiveDraft && text.text.isEmpty) {
      setState(() => sensitiveDraft = false);
    }
    // Some IMEs commit without changing the text. onChanged alone misses it.
    if (committed && !changingBuffer) schedule();
  }

  void replaceBuffer(TextEditingValue value) {
    changingBuffer = true;
    try {
      if (value.text.isEmpty && !private) sensitiveDraft = false;
      text.value = value;
    } finally {
      changingBuffer = false;
    }
  }

  void invalidateMode() {
    modeEpoch++;
    activeSend = null;
    sending = false;
    debounce?.cancel();
  }

  void keepCompose() {
    if (!sensitive && !live) {
      widget.model.rememberDraft(draftContext, text.value);
    }
  }

  void restoreCompose() {
    replaceBuffer(
      sensitive ? TextEditingValue.empty : widget.model.draft(draftContext),
    );
  }

  void changed() {
    final next = widget.model.target;
    final contextChanged =
        next?.deviceId != origin?.deviceId ||
        next?.sessionId != origin?.sessionId ||
        draftContext != widget.model.draftContext;
    final editorChanged =
        lastEditorRevision != widget.model.state?.editor?.revision;
    lastEditorRevision = widget.model.state?.editor?.revision;
    if (contextChanged ||
        (sensitive && editorChanged) ||
        (live && widget.model.state?.editor?.revision != revision)) {
      invalidateMode();
      keepCompose();
      live = false;
      if (sensitive) replaceBuffer(TextEditingValue.empty);
      draftContext = widget.model.draftContext;
      restoreCompose();
      origin = next;
      revision = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      invalidateMode();
      keepCompose();
      live = false;
      restoreCompose();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    keepCompose();
    widget.model.removeListener(changed);
    WidgetsBinding.instance.removeObserver(this);
    text.removeListener(compositionChanged);
    text.clear();
    text.dispose();
    super.dispose();
  }

  Future<void> send({bool replace = false}) async {
    final captured = origin;
    if (captured == null || sending) return;
    final epoch = modeEpoch;
    final request = ++sendSequence;
    activeSend = request;
    final sentRevision = revision;
    setState(() => sending = true);
    final value = text.text;
    final sentContext = draftContext;
    final result = await widget.model.command(
      CommandKind.text,
      origin: captured,
      value: value,
      replaceText: replace,
      privateText: sensitive,
      editorRevision: replace ? revision : widget.model.state?.editor?.revision,
    );
    if (mounted) {
      if (activeSend != request ||
          epoch != modeEpoch ||
          origin?.deviceId != captured.deviceId ||
          origin?.sessionId != captured.sessionId ||
          draftContext != sentContext ||
          replace && revision != sentRevision) {
        return;
      }
      setState(() {
        activeSend = null;
        sending = false;
        if (!replace &&
            result?.delivery == Delivery.confirmed &&
            origin?.deviceId == captured.deviceId &&
            origin?.sessionId == captured.sessionId &&
            draftContext == sentContext &&
            text.text == value) {
          replaceBuffer(TextEditingValue.empty);
          keepCompose();
        }
      });
      if (replace &&
          live &&
          (result?.delivery == Delivery.sent ||
              result?.delivery == Delivery.confirmed) &&
          text.text != value) {
        schedule();
      }
      if (replace &&
          result?.delivery != Delivery.sent &&
          result?.delivery != Delivery.confirmed) {
        setState(() {
          invalidateMode();
          live = false;
          restoreCompose();
        });
      }
    }
  }

  void schedule() {
    keepCompose();
    debounce?.cancel();
    if (live && text.value.composing.isCollapsed) {
      debounce = Timer(
        const Duration(milliseconds: 180),
        () => send(replace: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ScreenInfo>(
    valueListenable: widget.model.screen,
    builder: (context, frame, _) => LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          SizedBox(
            height: frame.hidden == true
                ? 48
                : (constraints.maxHeight * 0.36).clamp(110, 240),
            child: ScreenViewer(model: widget.model),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text(t('compose')),
                      selected: !live,
                      onSelected: (_) {
                        final wasLive = live;
                        if (wasLive) invalidateMode();
                        setState(() => live = false);
                        if (wasLive) restoreCompose();
                      },
                    ),
                    ChoiceChip(
                      label: Text(t('liveEdit')),
                      selected: live,
                      onSelected: (_) {
                        if (live) return;
                        final editor = widget.model.state?.editor;
                        if (editor == null) {
                          widget.model.report('noEditor');
                          return;
                        }
                        keepCompose();
                        invalidateMode();
                        origin = widget.model.target;
                        revision = editor.revision;
                        live = true;
                        replaceBuffer(
                          TextEditingValue(
                            text: editor.text,
                            selection: TextSelection(
                              baseOffset: editor.start.clamp(
                                0,
                                editor.text.length,
                              ),
                              extentOffset: editor.end.clamp(
                                0,
                                editor.text.length,
                              ),
                            ),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: Text(t('privateText')),
                      selected: private,
                      onSelected: (value) {
                        invalidateMode();
                        if (value) {
                          sensitiveDraft = true;
                          widget.model.clearDraft(draftContext);
                        }
                        setState(() {
                          private = value;
                          if (!private && text.text.isEmpty) {
                            sensitiveDraft = false;
                          }
                        });
                        keepCompose();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  // Android's current text-input channel does not implement
                  // updateConfig. A security-mode change needs a new client,
                  // not merely obscured Flutter pixels over the old IME flags.
                  key: ValueKey((private, sensitive)),
                  controller: text,
                  autofocus: true,
                  obscureText: private,
                  enableSuggestions: !sensitive,
                  autocorrect: !sensitive,
                  enableIMEPersonalizedLearning: !sensitive,
                  minLines: 1,
                  maxLines: private ? 1 : 3,
                  keyboardType: private
                      ? TextInputType.text
                      : sensitive
                      ? TextInputType.visiblePassword
                      : TextInputType.multiline,
                  decoration: InputDecoration(hintText: t('textHint')),
                  onChanged: (_) => schedule(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final contextAtPaste = draftContext;
                        final targetAtPaste = origin;
                        final modeAtPaste = modeEpoch;
                        final bufferAtPaste = bufferRevision;
                        final clipboard = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (!mounted ||
                            clipboard?.text == null ||
                            modeEpoch != modeAtPaste ||
                            bufferRevision != bufferAtPaste ||
                            draftContext != contextAtPaste ||
                            origin?.deviceId != targetAtPaste?.deviceId ||
                            origin?.sessionId != targetAtPaste?.sessionId) {
                          return;
                        }
                        text.value = TextEditingValue(
                          text: clipboard!.text!,
                          selection: TextSelection.collapsed(
                            offset: clipboard.text!.length,
                          ),
                        );
                        schedule();
                      },
                      icon: const Icon(Icons.content_paste),
                      label: Text(t('paste')),
                    ),
                    FilledButton.icon(
                      onPressed: sending ? null : () => send(replace: live),
                      icon: const Icon(Icons.send),
                      label: Text(t('send')),
                    ),
                    TextButton(
                      onPressed: () {
                        text.clear();
                        schedule();
                      },
                      child: Text(t('clear')),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Semantics(header: true, child: Text(t('tvEditingKeys'))),
                if (!live) Text(t('tvEditingBody')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final key in [
                      ('tvBackspace', 67, Icons.backspace_outlined),
                      ('tvDelete', 112, Icons.keyboard_alt_outlined),
                      ('tvCursorLeft', 21, Icons.arrow_back),
                      ('tvCursorRight', 22, Icons.arrow_forward),
                      ('tvEnter', 66, Icons.keyboard_return),
                    ])
                      RemoteButton(
                        model: widget.model,
                        code: key.$2,
                        label: t(key.$1),
                        icon: key.$3,
                        compact: true,
                      ),
                  ],
                ),
                if (sensitive)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(t('privateDraft')),
                  ),
                if (!sensitive)
                  ExpansionTile(
                    title: Text(t('vnc')),
                    children: [
                      Text(t('tvClipboardBody')),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => widget.model.command(
                              CommandKind.paste,
                              origin: origin,
                              value: text.text,
                              privateText: sensitive,
                            ),
                            child: Text(t('tvClipboard')),
                          ),
                          TextButton(
                            onPressed: () => widget.model.command(
                              CommandKind.key,
                              origin: origin,
                              code: 279,
                            ),
                            child: Text(t('sendClipboardPaste')),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'viewer.dart';
import 'widgets.dart';

class KeyboardPage extends StatefulWidget {
  const KeyboardPage(this.model, {super.key});
  final TvModel model;
  @override
  State<KeyboardPage> createState() => KeyboardPageState();
}

class KeyboardPageState extends State<KeyboardPage>
    with WidgetsBindingObserver {
  final text = TextEditingController();
  var inputFocus = FocusNode();
  Timer? debounce;
  Timer? editingRepeat;
  bool live = false;
  bool pausedEdit = false;
  bool followEditor = true;
  bool entryUntouched = true;
  bool editedLive = false;
  bool finishing = false;
  int? submittedEditor;
  String lastSubmittedText = '';
  Future<bool>? inFlight;
  (bool, bool, bool)? inputMode;
  bool keyboardWasVisible = false;
  bool keyboardDismissed = false;
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
    final editor = widget.model.state?.editor;
    if (editor != null) bindEditor(editor);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        inputFocus.requestFocus();
      }
    });
  }

  bool get dirtyLive => (live || pausedEdit) && text.text != lastSubmittedText;

  void bindEditor(EditorInfo editor, {bool preserveCompose = true}) {
    if (preserveCompose) keepCompose();
    invalidateMode();
    origin = widget.model.target;
    draftContext = widget.model.draftContext;
    revision = editor.revision;
    lastEditorRevision = editor.revision;
    live = true;
    pausedEdit = false;
    editedLive = false;
    lastSubmittedText = editor.text;
    replaceBuffer(
      TextEditingValue(
        text: editor.text,
        selection: TextSelection(
          baseOffset: editor.start.clamp(0, editor.text.length),
          extentOffset: editor.end.clamp(0, editor.text.length),
        ),
      ),
    );
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
    editingRepeat?.cancel();
  }

  void keepCompose() {
    if (!sensitive && !live && !pausedEdit) {
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
    final editor = widget.model.state?.editor;
    final oldEditorRevision = lastEditorRevision;
    final canFollow = !sensitive && !composing && !sending && !dirtyLive;
    final contextChanged =
        next?.deviceId != origin?.deviceId ||
        next?.sessionId != origin?.sessionId ||
        draftContext != widget.model.draftContext;
    final editorChanged = lastEditorRevision != editor?.revision;
    lastEditorRevision = editor?.revision;
    // A late first editor must not replace a draft the person has started.
    final sameTarget =
        next?.deviceId == origin?.deviceId &&
        next?.sessionId == origin?.sessionId;
    if (sameTarget &&
        pausedEdit &&
        followEditor &&
        canFollow &&
        editor != null &&
        editor.revision != submittedEditor) {
      bindEditor(editor, preserveCompose: false);
      setState(() {});
      return;
    }
    if (sameTarget &&
        oldEditorRevision == null &&
        editor != null &&
        !live &&
        !pausedEdit &&
        !sensitive) {
      if (followEditor && entryUntouched && text.text.isEmpty && !composing) {
        bindEditor(editor);
        setState(() {});
      } else {
        draftContext = widget.model.draftContext;
      }
      return;
    }
    if (contextChanged ||
        (sensitive && editorChanged) ||
        (live && editor?.revision != revision)) {
      final wasLive = live || pausedEdit;
      invalidateMode();
      keepCompose();
      live = false;
      pausedEdit = false;
      if (sameTarget && wasLive && !sensitive && !canFollow) {
        // Preserve an unfinished ordinary edit on this page, but never send it
        // into the replacement editor or store TV contents as a Compose draft.
        pausedEdit = true;
        followEditor = false;
      } else if (sameTarget && wasLive && followEditor && canFollow) {
        if (editor != null) {
          bindEditor(editor, preserveCompose: false);
        } else {
          replaceBuffer(TextEditingValue.empty);
          entryUntouched = true;
        }
      } else {
        if (sensitive) replaceBuffer(TextEditingValue.empty);
        draftContext = widget.model.draftContext;
        restoreCompose();
      }
      draftContext = widget.model.draftContext;
      origin = next;
      if (!live) revision = null;
      if (mounted) setState(() {});
    } else if (live && editor != null && !editedLive && canFollow) {
      // Once the person edits, older same-revision echoes cannot move their
      // caret or replace newer local text. A pristine field can track the TV.
      replaceBuffer(
        TextEditingValue(
          text: editor.text,
          selection: TextSelection(
            baseOffset: editor.start.clamp(0, editor.text.length),
            extentOffset: editor.end.clamp(0, editor.text.length),
          ),
        ),
      );
      lastSubmittedText = editor.text;
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final visible = View.of(context).viewInsets.bottom > 0;
    if (visible) keyboardDismissed = false;
    if (keyboardWasVisible && !visible && inputFocus.hasFocus) {
      keyboardDismissed = true;
    }
    keyboardWasVisible = visible;
  }

  FocusNode configuredInputFocus() {
    final next = (private, sensitive, live || pausedEdit);
    final reattaching = inputMode != null && inputMode != next;
    inputMode = next;
    // A security-mode change replaces the platform input client. Preserve an
    // active IME with a fresh keyboard token. Requesting the already-primary
    // node is a no-op in FocusNode, so a recreated EditableText would stay
    // detached. Nodes change only with the client config, never per rebuild.
    if (reattaching) {
      final previous = inputFocus;
      final restore = previous.hasFocus && !keyboardDismissed && !finishing;
      inputFocus = FocusNode();
      if (restore) inputFocus.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
    return inputFocus;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      invalidateMode();
      keepCompose();
      live = false;
      pausedEdit = false;
      followEditor = false;
      restoreCompose();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    editingRepeat?.cancel();
    keepCompose();
    widget.model.removeListener(changed);
    WidgetsBinding.instance.removeObserver(this);
    text.removeListener(compositionChanged);
    text.clear();
    text.dispose();
    inputFocus.dispose();
    super.dispose();
  }

  Future<bool> send({bool replace = false}) {
    if (sending) return inFlight ?? Future.value(false);
    final operation = sendValue(replace: replace);
    inFlight = operation;
    return operation;
  }

  Future<bool> sendValue({bool replace = false}) async {
    final captured = origin;
    if (captured == null || pausedEdit) return false;
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
        return false;
      }
      setState(() {
        activeSend = null;
        sending = false;
        if (replace &&
            (result?.delivery == Delivery.sent ||
                result?.delivery == Delivery.confirmed)) {
          lastSubmittedText = value;
        }
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
          pausedEdit = true;
          followEditor = false;
        });
      }
    }
    return result?.delivery == Delivery.sent ||
        result?.delivery == Delivery.confirmed;
  }

  Future<bool> flushLive() async {
    debounce?.cancel();
    if (pausedEdit) return false;
    if (!live) return true;
    final epoch = modeEpoch;
    if (sending && !await inFlight!) return false;
    if (!mounted || epoch != modeEpoch || !live) return false;
    debounce?.cancel();
    if (!dirtyLive) return true;
    return send(replace: true);
  }

  Future<bool> prepareToLeave() async {
    if (finishing) return false;
    setState(() => finishing = true);
    editingRepeat?.cancel();
    inputFocus.unfocus();
    // Leaving deliberately commits the visible composition, never TV Enter.
    replaceBuffer(text.value.copyWith(composing: TextRange.empty));
    final epoch = modeEpoch;
    final flushed = await flushLive();
    if (!mounted) return false;
    bool leave = flushed;
    if (!flushed && (pausedEdit || epoch == modeEpoch)) {
      leave = await confirm(
        context,
        'leaveKeyboardTitle',
        'leaveKeyboardBody',
        'closeKeyboard',
        extraBody: sensitive ? 'privateDraft' : null,
      );
    }
    if (mounted) setState(() => finishing = false);
    return leave;
  }

  void editLocally(int code, {bool repeat = false}) {
    if (finishing) return;
    final value = text.value;
    final bounds = <int>[0];
    for (final character in value.text.characters) {
      bounds.add(bounds.last + character.length);
    }
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    var start = selection.start.clamp(0, value.text.length);
    var end = selection.end.clamp(start, value.text.length);
    final previous = bounds.lastWhere(
      (offset) => offset < start,
      orElse: () => 0,
    );
    final next = bounds.firstWhere(
      (offset) => offset > end,
      orElse: () => value.text.length,
    );
    if (code == 21 || code == 22) {
      final cursor = code == 21
          ? (start == end ? previous : start)
          : (start == end ? next : end);
      text.value = value.copyWith(
        selection: TextSelection.collapsed(offset: cursor),
        composing: TextRange.empty,
      );
      entryUntouched = false;
      editedLive = true;
      return;
    }
    if (start == end) {
      if (code == 67) start = previous;
      if (code == 112) end = next;
    }
    text.value = TextEditingValue(
      text: value.text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
    schedule(repeat: repeat);
  }

  Future<bool> prepareEnterOnTv() async {
    if (finishing || pausedEdit) return false;
    setState(() => finishing = true);
    editingRepeat?.cancel();
    replaceBuffer(text.value.copyWith(composing: TextRange.empty));
    final flushed = await flushLive();
    if (mounted) setState(() => finishing = false);
    return flushed && mounted;
  }

  void enteringOnTv() {
    submittedEditor = widget.model.state?.editor?.revision;
    invalidateMode();
    setState(() {
      live = false;
      pausedEdit = true;
      followEditor = true;
    });
  }

  Widget localEditingButton(int code, String label, IconData icon) {
    void stop() => editingRepeat?.cancel();
    void hold() {
      stop();
      editLocally(code, repeat: true);
      editingRepeat = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => editLocally(code, repeat: true),
      );
    }

    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: t('hold')): hold,
        CustomSemanticsAction(label: t('release')): stop,
      },
      child: Listener(
        onPointerUp: (_) => stop(),
        onPointerCancel: (_) => stop(),
        child: Tooltip(
          message: label,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size(56, 56),
              padding: const EdgeInsets.all(12),
            ),
            onPressed: finishing ? null : () => editLocally(code),
            onLongPress: finishing ? null : hold,
            child: Icon(icon, semanticLabel: label),
          ),
        ),
      ),
    );
  }

  void schedule({bool repeat = false}) {
    entryUntouched = false;
    if (live) editedLive = true;
    keepCompose();
    if (!repeat) debounce?.cancel();
    if (live &&
        !finishing &&
        text.value.composing.isCollapsed &&
        (!repeat || debounce?.isActive != true)) {
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
                      selected: !live && !pausedEdit,
                      onSelected: (_) {
                        if (finishing) return;
                        entryUntouched = false;
                        followEditor = false;
                        final wasLive = live || pausedEdit;
                        if (wasLive) invalidateMode();
                        setState(() {
                          live = false;
                          pausedEdit = false;
                        });
                        if (wasLive) restoreCompose();
                      },
                    ),
                    ChoiceChip(
                      label: Text(t('liveEdit')),
                      selected: live,
                      onSelected: (_) {
                        if (live || finishing) return;
                        entryUntouched = false;
                        final editor = widget.model.state?.editor;
                        if (editor == null) {
                          widget.model.report('noEditor');
                          return;
                        }
                        followEditor = true;
                        bindEditor(editor);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: Text(t('privateText')),
                      selected: private,
                      onSelected: (value) {
                        if (finishing) return;
                        entryUntouched = false;
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
                  key: ValueKey((private, sensitive, live || pausedEdit)),
                  controller: text,
                  focusNode: configuredInputFocus(),
                  onTap: () => keyboardDismissed = false,
                  readOnly: finishing,
                  obscureText: private,
                  enableSuggestions: !sensitive && !live && !pausedEdit,
                  autocorrect: !sensitive && !live && !pausedEdit,
                  enableIMEPersonalizedLearning:
                      !sensitive && !live && !pausedEdit,
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
                if (pausedEdit) Text(t('pausedEditingBody')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: finishing
                          ? null
                          : () async {
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
                                  origin?.sessionId !=
                                      targetAtPaste?.sessionId) {
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
                      onPressed: sending || finishing || pausedEdit
                          ? null
                          : () => send(replace: live),
                      icon: const Icon(Icons.send),
                      label: Text(t('send')),
                    ),
                    TextButton(
                      onPressed: finishing
                          ? null
                          : () {
                              text.clear();
                              schedule();
                            },
                      child: Text(t('clear')),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    t(live || pausedEdit ? 'editingKeys' : 'tvEditingKeys'),
                  ),
                ),
                if (!pausedEdit)
                  Text(t(live ? 'liveEditingBody' : 'tvEditingBody')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (live || pausedEdit) ...[
                      localEditingButton(
                        67,
                        t('backspace'),
                        Icons.backspace_outlined,
                      ),
                      localEditingButton(
                        112,
                        t('delete'),
                        Icons.keyboard_alt_outlined,
                      ),
                      localEditingButton(21, t('cursorLeft'), Icons.arrow_back),
                      localEditingButton(
                        22,
                        t('cursorRight'),
                        Icons.arrow_forward,
                      ),
                      RemoteButton(
                        model: widget.model,
                        code: 66,
                        label: t('tvEnter'),
                        icon: Icons.keyboard_return,
                        compact: true,
                        beforePress: prepareEnterOnTv,
                        onDispatch: enteringOnTv,
                      ),
                    ] else
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

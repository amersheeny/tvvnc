import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'catalog_pages.dart';
import 'device_form.dart';
import 'diagnostics_page.dart';
import 'keyboard_page.dart';
import 'remote_page.dart';
import 'shortcuts_page.dart';
import 'widgets.dart';

class Console extends StatefulWidget {
  const Console({
    super.key,
    required this.model,
    required this.theme,
    required this.onTheme,
  });
  final TvModel model;
  final ThemeMode theme;
  final ValueChanged<ThemeMode> onTheme;
  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> with WidgetsBindingObserver {
  String page = 'devices';
  final pageHistory = <LocalHistoryEntry>[];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final keyboardKey = GlobalKey<KeyboardPageState>();
  bool leavingKeyboard = false;
  bool drawerOpen = false;
  String? selectedId;
  int seenMessage = 0;
  bool showingPair = false;
  BuildContext? pairingContext;
  @override
  void initState() {
    super.initState();
    selectedId = widget.model.selected?.id;
    widget.model.addListener(changed);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.model.removeListener(changed);
    WidgetsBinding.instance.removeObserver(this);
    clearPageHistory();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.model.networkPermissionDenied) {
      widget.model.guard(widget.model.refreshNetworkAccess);
    }
  }

  void changed() {
    if (selectedId != widget.model.selected?.id) {
      selectedId = widget.model.selected?.id;
      clearPageHistory();
    }
    final dialog = pairingContext;
    if (dialog != null && widget.model.state?.pairingState != 'waiting') {
      pairingContext = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (dialog.mounted) Navigator.of(dialog).maybePop();
      });
    }
    if (widget.model.messageId != seenMessage) {
      seenMessage = widget.model.messageId;
      final message = widget.model.message;
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
        });
      }
    }
    if (widget.model.state?.pairingState == 'waiting' && !showingPair) {
      showingPair = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) pairingDialog();
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> pairingDialog() async {
    final target = widget.model.target;
    if (target == null) {
      showingPair = false;
      return;
    }
    final code = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        pairingContext = context;
        return AlertDialog(
          title: Text(t('pairRemote')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.model.selected?.name ?? ''),
              const SizedBox(height: 12),
              Text(t('pairingWaiting')),
              const SizedBox(height: 16),
              TextField(
                controller: code,
                autofocus: true,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                ],
                decoration: InputDecoration(labelText: t('pairingCode')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (code.text.length == 6) Navigator.pop(context, code.text);
              },
              child: Text(t('pair')),
            ),
          ],
        );
      },
    );
    code.clear();
    code.dispose();
    pairingContext = null;
    if (value == null &&
        widget.model.target?.sessionId == target.sessionId &&
        widget.model.state?.pairingState == 'waiting') {
      await widget.model.guard(
        () => widget.model.api.cancelPairing(target.deviceId, target.sessionId),
      );
    } else if (value != null) {
      await widget.model.guard(
        () => widget.model.api.submitPairingCode(
          target.deviceId,
          target.sessionId,
          value,
        ),
      );
    }
    showingPair = false;
  }

  void clearPageHistory() {
    final entries = pageHistory.toList();
    // Untrack first: removing entries calls onRemove synchronously. A reset
    // must not restore pages from an old TV or rebuild during disposal.
    pageHistory.clear();
    page = 'devices';
    for (final entry in entries.reversed) {
      entry.remove();
    }
  }

  Future<bool> prepareKeyboardExit() async {
    if (page != 'keyboard') return true;
    if (leavingKeyboard) return false;
    leavingKeyboard = true;
    final device = selectedId;
    final session = widget.model.target?.sessionId;
    try {
      final allowed = await keyboardKey.currentState?.prepareToLeave() ?? true;
      return allowed &&
          mounted &&
          page == 'keyboard' &&
          selectedId == device &&
          widget.model.target?.sessionId == session &&
          ModalRoute.of(context)?.isCurrent == true;
    } finally {
      leavingKeyboard = false;
    }
  }

  Future<void> closeKeyboard() async {
    if (!await prepareKeyboardExit() || !mounted) return;
    if (pageHistory.isNotEmpty) pageHistory.last.remove();
  }

  Future<void> navigate(String next) async {
    final current = widget.model.selected == null ? 'devices' : page;
    if (next == current ||
        (widget.model.selected == null && next != 'devices')) {
      return;
    }
    if (current == 'keyboard' && !await prepareKeyboardExit()) return;
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (next == 'devices') {
      setState(clearPageHistory);
      return;
    }
    late final LocalHistoryEntry entry;
    entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () {
        if (!pageHistory.remove(entry) || !mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => page = current);
      },
    );
    pageHistory.add(entry);
    ModalRoute.of(context)!.addLocalHistoryEntry(entry);
    setState(() => page = next);
  }

  void select(TvProfile profile) {
    clearPageHistory();
    // connect publishes its selected TV synchronously. Let changed() reset
    // that identity before adding history, without awaiting network or consent.
    unawaited(widget.model.connect(profile));
    navigate('remote');
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final current = m.selected == null ? 'devices' : page;
    final window = MediaQuery.sizeOf(context);
    final compactKeyboard =
        current == 'keyboard' &&
        window.width > window.height &&
        MediaQuery.viewInsetsOf(context).bottom > 0;
    final entries = [
      ('devices', Icons.tv),
      ('remote', Icons.settings_remote_outlined),
      ('allButtons', Icons.dialpad),
      ('touchpad', Icons.swipe),
      ('keyboard', Icons.keyboard_outlined),
      ('apps', Icons.apps),
      ('inputs', Icons.input),
      ('macros', Icons.playlist_play),
      ('diagnostics', Icons.monitor_heart_outlined),
      ('settings', Icons.settings_outlined),
    ];
    final body = switch (current) {
      'devices' => DevicesPage(model: m, onSelected: select),
      'remote' => RemotePage(
        key: ValueKey('remote-${m.selected?.id}'),
        model: m,
        onPage: navigate,
      ),
      'touchpad' => RemotePage(
        key: ValueKey('touch-${m.selected?.id}'),
        model: m,
        onPage: navigate,
        initialMode: 'touchpad',
      ),
      'keyboard' => KeyboardPage(m, key: keyboardKey),
      'apps' => CatalogPage(m, key: const ValueKey('apps'), apps: true),
      'inputs' => CatalogPage(m, key: const ValueKey('inputs'), apps: false),
      'allButtons' => AllButtonsPage(m),
      'diagnostics' => DiagnosticsPage(m),
      'macros' => ShortcutsPage(m),
      _ => SettingsPage(m, theme: widget.theme, onTheme: widget.onTheme),
    };
    return PopScope(
      canPop: current != 'keyboard' || drawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || current != 'keyboard') return;
        if (scaffoldKey.currentState?.isDrawerOpen == true) {
          scaffoldKey.currentState!.closeDrawer();
        } else {
          unawaited(closeKeyboard());
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        onDrawerChanged: (value) => setState(() => drawerOpen = value),
        appBar: AppBar(
          toolbarHeight: compactKeyboard ? 48 : null,
          title: Text(current == 'devices' ? t('appTitle') : m.selected!.name),
          actions: current == 'devices'
              ? null
              : [
                  IconButton(
                    tooltip: t(
                      current == 'keyboard' ? 'closeKeyboard' : 'devices',
                    ),
                    icon: Icon(
                      current == 'keyboard' ? Icons.close : Icons.devices,
                    ),
                    onPressed: current == 'keyboard'
                        ? closeKeyboard
                        : () => navigate('devices'),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'connect') await m.connect(m.selected!);
                      if (value == 'disconnect') await m.disconnect();
                      if (value == 'pairRemote') {
                        await m.guard(() => m.api.pairRemote(m.selected!.id));
                      }
                      if (value == 'edit' && context.mounted) {
                        await editDevice(context, m, profile: m.selected);
                      }
                    },
                    itemBuilder: (_) => [
                      for (final id in [
                        'connect',
                        'disconnect',
                        'pairRemote',
                        'edit',
                      ])
                        PopupMenuItem(value: id, child: Text(t(id))),
                    ],
                  ),
                ],
        ),
        drawer: NavigationDrawer(
          selectedIndex: entries.indexWhere((e) => e.$1 == current),
          onDestinationSelected: (index) {
            Navigator.pop(context);
            if (entries[index].$1 == 'devices' || m.selected != null) {
              navigate(entries[index].$1);
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
              child: Text(
                t('appTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final entry in entries)
              NavigationDrawerDestination(
                icon: Icon(entry.$2),
                label: Text(t(entry.$1)),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (current != 'devices' && m.networkPermissionDenied)
                NetworkPermissionPanel(m),
              if (current != 'devices' && !compactKeyboard)
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: InkWell(
                    onTap: () => navigate('diagnostics'),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            m.state?.connectionStage == 'connected'
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.state?.connectionStage == 'connected'
                                  ? '${m.state!.transports.where((p) => p.state == Availability.ready).map((p) => t(p.id == 'remote'
                                        ? 'androidRemote'
                                        : p.id == 'sony'
                                        ? 'sonyApi'
                                        : 'vnc')).join(', ')} · ${t('connected')}'
                                  : t(
                                      m.loading
                                          ? 'connecting'
                                          : m.state?.connectionStage ??
                                                'disconnected',
                                    ),
                            ),
                          ),
                          if (m.state?.power != null) Text(t(m.state!.power!)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage(
    this.model, {
    super.key,
    required this.theme,
    required this.onTheme,
  });
  final TvModel model;
  final ThemeMode theme;
  final ValueChanged<ThemeMode> onTheme;
  Future<void> register(BuildContext context) async {
    final target = model.target;
    if (target == null) return;
    if (!await confirm(
      context,
      'sonyRegistrationTitle',
      'sonyRegistrationBody',
      'registerSony',
    )) {
      return;
    }
    if (model.target?.deviceId != target.deviceId ||
        model.target?.sessionId != target.sessionId) {
      return;
    }
    final started = await model.guard(() async {
      return await model.api.registerSony(
        target.deviceId,
        target.sessionId,
        null,
      );
    });
    if (started == null || !context.mounted) return;
    if (started) {
      await model.reload();
      model.report('connected');
      return;
    }
    final code = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('registerSony')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(model.selected?.name ?? ''),
            const SizedBox(height: 8),
            Text(t('sonyPinWaiting')),
            const SizedBox(height: 16),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              decoration: InputDecoration(labelText: t('sonyPin')),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, code.text),
            child: Text(t('registerSony')),
          ),
        ],
      ),
    );
    code.clear();
    code.dispose();
    if (pin != null) {
      await model.guard(() async {
        await model.api.registerSony(target.deviceId, target.sessionId, pin);
        await model.reload();
        model.report('connected');
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(t('settings'), style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      ListTile(
        leading: const Icon(Icons.tv),
        title: Text(model.selected?.name ?? t('tv')),
        subtitle: Text(model.selected?.host ?? ''),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => editDevice(context, model, profile: model.selected),
      ),
      ListTile(
        leading: const Icon(Icons.link),
        title: Text(t('pairRemote')),
        onTap: () =>
            model.guard(() => model.api.pairRemote(model.selected!.id)),
      ),
      ListTile(
        leading: const Icon(Icons.tune),
        title: Text(t('customize')),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => CustomizePage(model)),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.link),
        title: Text(t('registerSony')),
        onTap: () => register(context),
      ),
      CheckboxListTile(
        title: Text(t('droidConfirmed')),
        subtitle: Text(t('droidShortcuts')),
        value: model.selected?.droidVnc ?? false,
        onChanged: (value) =>
            model.save(model.selected!.updated(droidVnc: value), null),
      ),
      CheckboxListTile(
        title: Text(t('confirmInput')),
        value: model.selected?.pointerVerified ?? false,
        onChanged: (value) =>
            model.save(model.selected!.updated(pointerVerified: value), null),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(t('networkMacHelp')),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(t('secretsSaved')),
      ),
      const Divider(),
      for (final entry in [
        (ThemeMode.system, 'systemTheme'),
        (ThemeMode.light, 'light'),
        (ThemeMode.dark, 'dark'),
      ])
        Semantics(
          checked: theme == entry.$1,
          inMutuallyExclusiveGroup: true,
          child: ListTile(
            title: Text(t(entry.$2)),
            leading: Icon(
              theme == entry.$1
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            onTap: () => onTheme(entry.$1),
          ),
        ),
      const Divider(),
      Padding(padding: const EdgeInsets.all(16), child: Text(t('classicVnc'))),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(t('noAudioSaved')),
      ),
      OutlinedButton(
        onPressed: () => model.guard(model.api.openSettings),
        child: Text(t('openSettings')),
      ),
    ],
  );
}

class CustomizePage extends StatefulWidget {
  const CustomizePage(this.model, {super.key});
  final TvModel model;
  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  late final profile = widget.model.selected!;
  late List<String> layout = [
    ...(profile.layout.isEmpty ? defaultLayout : profile.layout),
  ];
  String label(String id) =>
      widget.model.state?.buttons.where((b) => b.id == id).firstOrNull?.name ??
      t(id);
  void move(int from, int to) {
    setState(() {
      final item = layout.removeAt(from);
      layout.insert(to, item);
    });
  }

  Future<void> add() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: ListView(
            children: [
              for (final button
                  in widget.model.state?.buttons.where(
                        (b) => !b.disruptive && !layout.contains(b.id),
                      ) ??
                      <TvButton>[])
                ListTile(
                  title: Text(t(button.name)),
                  onTap: () => Navigator.pop(context, button.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (id != null && mounted) setState(() => layout.add(id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(t('customize')),
      actions: [
        TextButton(
          onPressed: () async {
            await widget.model.save(profile.updated(layout: layout), null);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(t('save')),
        ),
      ],
    ),
    body: ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: layout.length,
      header: Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => setState(() => layout = [...defaultLayout]),
            child: Text(t('resetLayout')),
          ),
          TextButton.icon(
            onPressed: add,
            icon: const Icon(Icons.add),
            label: Text(t('allButtons')),
          ),
        ],
      ),
      onReorderItem: move,
      itemBuilder: (context, index) => Card(
        key: ValueKey(layout[index]),
        child: Column(
          children: [
            ListTile(
              title: Text(t(label(layout[index]))),
              trailing: IconButton(
                tooltip: t('delete'),
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => layout.removeAt(index)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: index == 0 ? null : () => move(index, index - 1),
                  tooltip: t('moveUp'),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  onPressed: index == layout.length - 1
                      ? null
                      : () => move(index, index + 1),
                  tooltip: t('moveDown'),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

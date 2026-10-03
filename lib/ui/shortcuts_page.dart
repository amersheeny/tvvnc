import 'package:flutter/material.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'widgets.dart';
import 'copy.dart';

class ShortcutsPage extends StatelessWidget {
  const ShortcutsPage(this.model, {super.key});
  final TvModel model;
  Future<void> edit(BuildContext context, TvMacro? macro) async {
    final profile = model.selected;
    if (profile == null) return;
    final result = await Navigator.push<TvMacro>(
      context,
      MaterialPageRoute(builder: (_) => ShortcutEditor(model, macro: macro)),
    );
    if (result == null) return;
    await model.updateSaved(
      profile.id,
      (latest) => latest.updated(
        macros: [...latest.macros.where((m) => m.id != result.id), result],
      ),
    );
  }

  Future<void> remove(BuildContext context, TvMacro macro) async {
    final id = model.selected?.id;
    if (id == null) return;
    final tvName = model.selected!.name;
    final saved = await model.updateSaved(
      id,
      (latest) => latest.updated(
        macros: latest.macros.where((m) => m.id != macro.id).toList(),
      ),
    );
    if (saved == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final number = model.nextShortcutDeletion();
    final colors = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        persist: true,
        backgroundColor: colors.inverseSurface,
        content: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Copy.format('shortcutDeletedNamed', {
                      'shortcut': macro.name,
                    }),
                    style: TextStyle(color: colors.onInverseSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Copy.format('shortcutDeletionContext', {
                      'number': '$number',
                      'tv': tvName,
                    }),
                    style: TextStyle(color: colors.onInverseSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t('dismiss'),
              color: colors.onInverseSurface,
              onPressed: () => messenger.hideCurrentSnackBar(
                reason: SnackBarClosedReason.dismiss,
              ),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        action: SnackBarAction(
          label: t('undo'),
          textColor: colors.inversePrimary,
          onPressed: () {
            model.updateSaved(
              id,
              (latest) => latest.macros.any((m) => m.id == macro.id)
                  ? null
                  : latest.updated(macros: [...latest.macros, macro]),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(t('macros'), style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => edit(context, null),
        icon: const Icon(Icons.add),
        label: Text(t('addMacro')),
      ),
      if (model.selected?.macros.isEmpty ?? true)
        Padding(padding: const EdgeInsets.all(24), child: Text(t('noMacros'))),
      for (final macro in model.selected?.macros ?? <TvMacro>[])
        Card(
          child: ListTile(
            title: Text(macro.name),
            subtitle: Text('${t('steps')}: ${macro.steps.length}'),
            onTap: () => edit(context, macro),
            leading: IconButton(
              tooltip: t(
                model.state?.macroId == macro.id ? 'stopShortcut' : 'run',
              ),
              icon: Icon(
                model.state?.macroId == macro.id
                    ? Icons.stop
                    : Icons.play_arrow,
              ),
              onPressed: () => model.onTarget(
                (target) => model.state?.macroId == macro.id
                    ? model.api.stopMacro(target.deviceId, target.sessionId)
                    : model.api.runMacro(
                        target.deviceId,
                        target.sessionId,
                        macro.id,
                      ),
              ),
            ),
            trailing: IconButton(
              tooltip: t('delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => remove(context, macro),
            ),
          ),
        ),
    ],
  );
}

class ShortcutEditor extends StatefulWidget {
  const ShortcutEditor(this.model, {super.key, this.macro});
  final TvModel model;
  final TvMacro? macro;
  @override
  State<ShortcutEditor> createState() => _ShortcutEditorState();
}

class _ShortcutEditorState extends State<ShortcutEditor> {
  late final name = TextEditingController(text: widget.macro?.name ?? '');
  late final steps = [...?widget.macro?.steps];
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  String label(MacroStep step) => switch (step.action) {
    MacroAction.wake => t('wakeStep'),
    MacroAction.home => t('homeStep'),
    MacroAction.waitForTv => t('waitStep'),
    MacroAction.input =>
      '${t('inputStep')}: ${widget.model.state?.inputs.where((i) => i.uri == step.value).firstOrNull?.name ?? step.value}',
    MacroAction.app =>
      '${t('appStep')}: ${widget.model.state?.apps.where((i) => i.uri == step.value).firstOrNull?.name ?? step.value}',
    MacroAction.key => '${t('keyCode')}: ${step.value}',
    MacroAction.sony => step.value?.replaceFirst('sony:', '') ?? '',
  };
  Future<void> add() async {
    final step = await showModalBottomSheet<MacroStep>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  t('selectStep'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final item in [
                (MacroAction.wake, 'wakeStep'),
                (MacroAction.home, 'homeStep'),
                (MacroAction.waitForTv, 'waitStep'),
              ])
                ListTile(
                  title: Text(t(item.$2)),
                  onTap: () =>
                      Navigator.pop(context, MacroStep(action: item.$1)),
                ),
              for (final input in widget.model.state?.inputs ?? <TvInput>[])
                ListTile(
                  title: Text(input.name),
                  subtitle: Text(t('inputStep')),
                  onTap: () => Navigator.pop(
                    context,
                    MacroStep(action: MacroAction.input, value: input.uri),
                  ),
                ),
              for (final app in widget.model.state?.apps ?? <TvApplication>[])
                ListTile(
                  title: Text(app.name),
                  subtitle: Text(t('appStep')),
                  onTap: () => Navigator.pop(
                    context,
                    MacroStep(action: MacroAction.app, value: app.uri),
                  ),
                ),
              for (final button
                  in widget.model.state?.buttons.where((b) => !b.disruptive) ??
                      <TvButton>[])
                ListTile(
                  title: Text(t(button.name)),
                  subtitle: Text(t('allButtons')),
                  onTap: () => Navigator.pop(
                    context,
                    MacroStep(
                      action: button.sonyCode != null
                          ? MacroAction.sony
                          : MacroAction.key,
                      value: button.sonyCode != null
                          ? button.id
                          : button.androidCode?.toString(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (step != null && mounted) setState(() => steps.add(step));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(t(widget.macro == null ? 'addMacro' : 'editShortcut')),
      actions: [
        TextButton(
          onPressed: name.text.trim().isEmpty || steps.isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    TvMacro(
                      id:
                          widget.macro?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name.text.trim(),
                      steps: steps,
                    ),
                  );
                },
          child: Text(t('save')),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: t('shortcutName')),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < steps.length; i++)
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Text('${i + 1}'),
                  title: Text(label(steps[i])),
                  trailing: IconButton(
                    tooltip: t('delete'),
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => steps.removeAt(i)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: t('moveUp'),
                      onPressed: i == 0
                          ? null
                          : () => setState(() {
                              final item = steps.removeAt(i);
                              steps.insert(i - 1, item);
                            }),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: t('moveDown'),
                      onPressed: i == steps.length - 1
                          ? null
                          : () => setState(() {
                              final item = steps.removeAt(i);
                              steps.insert(i + 1, item);
                            }),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: add,
          icon: const Icon(Icons.add),
          label: Text(t('addStep')),
        ),
      ],
    ),
  );
}

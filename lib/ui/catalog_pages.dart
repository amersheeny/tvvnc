import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'widgets.dart';

Future<void> refreshTv(TvModel model) => model.onTarget((target) async {
  await model.api.refresh(target.deviceId, target.sessionId);
});

class CatalogPage extends StatefulWidget {
  const CatalogPage(this.model, {super.key, required this.apps});
  final TvModel model;
  final bool apps;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String query = '';
  String filter = 'all';
  Future<void> openLink() async {
    final target = widget.model.target;
    var input = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('openLink')),
        content: TextField(
          onChanged: (value) => input = value,
          decoration: InputDecoration(labelText: t('appLink')),
          autocorrect: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input),
            child: Text(t('launch')),
          ),
        ],
      ),
    );
    input = '';
    if (value != null && target != null) {
      await widget.model.command(CommandKind.app, origin: target, value: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.model.state;
    final captured = widget.model.target;
    final catalog = state?.apps ?? <TvApplication>[];
    final filtered = catalog
        .where(
          (app) =>
              (filter == 'all' ||
              filter == 'favorites' &&
                  widget.model.selected!.favorites.contains(app.id) ||
              filter == 'recent' &&
                  widget.model.selected!.recents.contains(app.uri)),
        )
        .toList();
    final apps = filtered
        .where((app) => app.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (filter == 'recent') {
      apps.sort(
        (a, b) => widget.model.selected!.recents
            .indexOf(a.uri)
            .compareTo(widget.model.selected!.recents.indexOf(b.uri)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => refreshTv(widget.model),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t(widget.apps ? 'apps' : 'inputs'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => refreshTv(widget.model),
                tooltip: t('refresh'),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (widget.apps) ...[
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: t('search'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final id in ['all', 'favorites', 'recent'])
                  ChoiceChip(
                    label: Text(t(id == 'all' ? 'apps' : id)),
                    selected: filter == id,
                    onSelected: (_) => setState(() => filter = id),
                  ),
              ],
            ),
            if (apps.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t(
                    catalog.isEmpty
                        ? 'noApps'
                        : filtered.isEmpty && filter == 'favorites'
                        ? 'noFavorites'
                        : filtered.isEmpty && filter == 'recent'
                        ? 'noRecentApps'
                        : 'noMatchingApps',
                  ),
                ),
              ),
            for (final app in apps)
              Card(
                child: ListTile(
                  leading: _AppIcon(widget.model, app, key: ValueKey(app.id)),
                  title: Text(app.name),
                  onTap: () => widget.model.command(
                    CommandKind.app,
                    origin: captured,
                    value: app.uri,
                  ),
                  trailing: IconButton(
                    tooltip: t(
                      widget.model.selected?.favorites.contains(app.id) == true
                          ? 'unfavorite'
                          : 'favorite',
                    ),
                    onPressed: () => widget.model.favorite(app),
                    icon: Icon(
                      widget.model.selected?.favorites.contains(app.id) == true
                          ? Icons.star
                          : Icons.star_border,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: openLink,
              icon: const Icon(Icons.link),
              label: Text(t('openLink')),
            ),
          ] else ...[
            if (state?.inputs.isEmpty ?? true)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(t('noInputs')),
              ),
            for (final input in state?.inputs ?? <TvInput>[])
              Card(
                child: ListTile(
                  leading: Icon(
                    input.uri.startsWith('tv:') || input.uri == 'command:Tv'
                        ? Icons.tv
                        : Icons.settings_input_hdmi,
                  ),
                  title: Text(
                    input.label?.isNotEmpty == true
                        ? '${input.name} — ${input.label}'
                        : input.name,
                  ),
                  subtitle: Text(
                    t(
                      input.uri.startsWith('command:')
                          ? 'unknown'
                          : input.connected
                          ? 'connected'
                          : 'disconnected',
                    ),
                  ),
                  trailing: input.selected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.chevron_right),
                  selected: input.selected,
                  onTap: () => widget.model.command(
                    CommandKind.input,
                    origin: captured,
                    value: input.uri,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// The sliver mounts only visible/nearby rows. Creating the Future in this
// child's build prevents a catalog rebuild from fetching every app icon.
class _AppIcon extends StatelessWidget {
  const _AppIcon(this.model, this.app, {super.key});
  final TvModel model;
  final TvApplication app;
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: model.icon(app),
    builder: (context, icon) => icon.data != null
        ? Image.memory(
            icon.data!,
            width: 40,
            height: 40,
            cacheWidth: 128,
            cacheHeight: 128,
            errorBuilder: (_, _, _) => const Icon(Icons.apps),
          )
        : const Icon(Icons.apps),
  );
}

class AllButtonsPage extends StatefulWidget {
  const AllButtonsPage(this.model, {super.key});
  final TvModel model;
  @override
  State<AllButtonsPage> createState() => _AllButtonsPageState();
}

class _AllButtonsPageState extends State<AllButtonsPage> {
  String query = '';
  String source = 'all';
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = (widget.model.state?.buttons ?? [])
        .where(
          (b) =>
              b.name.toLowerCase().contains(query.toLowerCase()) &&
              (source == 'all' ||
                  source == 'sony' && b.sonyCode != null ||
                  source == 'remote' && b.androidCode != null),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t('allButtons'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: t('search'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in [
              ('all', 'allButtons'),
              ('sony', 'sonyApi'),
              ('remote', 'androidRemote'),
            ])
              ChoiceChip(
                label: Text(t(entry.$2)),
                selected: source == entry.$1,
                onSelected: (_) => setState(() => source = entry.$1),
              ),
          ],
        ),
        for (final button in buttons)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: button.androidCode != null
                ? RemoteButton(
                    model: widget.model,
                    code: button.androidCode!,
                    label: button.id.startsWith('number')
                        ? button.id.substring(6)
                        : t(button.name),
                    icon: Icons.radio_button_unchecked,
                  )
                : availabilityHint(
                    button.state,
                    ListTile(
                      title: Text(button.name),
                      leading: Icon(
                        button.disruptive
                            ? Icons.warning_amber
                            : Icons.radio_button_unchecked,
                      ),
                      onTap: () async {
                        if (!canTry(button.state)) {
                          await explainControl(
                            context,
                            widget.model,
                            button.name,
                          );
                          return;
                        }
                        final target = widget.model.target;
                        var allowed = !button.disruptive;
                        if (button.disruptive) {
                          allowed =
                              await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(t('runButtonTitle')),
                                  content: Text(
                                    '${button.name}\n\n${t('runButtonBody')}',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(t('cancel')),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(t('send')),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        }
                        if (allowed && target != null) {
                          await widget.model.command(
                            CommandKind.sony,
                            origin: target,
                            value: button.id,
                            confirmed: button.disruptive,
                          );
                        }
                      },
                    ),
                  ),
          ),
        const Divider(),
        TextField(
          controller: code,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: t('keyCode')),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            final value = int.tryParse(code.text);
            if (value != null && value >= 0 && value <= 65535) {
              widget.model.command(CommandKind.key, code: value);
            }
          },
          child: Text(t('sendKey')),
        ),
      ],
    );
  }
}

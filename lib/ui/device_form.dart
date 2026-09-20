import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'widgets.dart';

Future<TvProfile?> editDevice(
  BuildContext context,
  TvModel model, {
  TvProfile? profile,
  DiscoveredTv? discovered,
}) => showDialog<TvProfile>(
  context: context,
  builder: (_) =>
      DeviceForm(model: model, profile: profile, discovered: discovered),
);

class DeviceForm extends StatefulWidget {
  const DeviceForm({
    super.key,
    required this.model,
    this.profile,
    this.discovered,
  });
  final TvModel model;
  final TvProfile? profile;
  final DiscoveredTv? discovered;
  @override
  State<DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<DeviceForm> with WidgetsBindingObserver {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.profile?.name ?? widget.discovered?.name ?? '',
  );
  late final host = TextEditingController(
    text: widget.profile?.host ?? widget.discovered?.host ?? '',
  );
  late final vncPort = TextEditingController(
    text:
        '${widget.profile?.vncPort ?? (widget.discovered?.service == '_rfb._tcp.' ? widget.discovered!.port : 5900)}',
  );
  late final remotePort = TextEditingController(
    text: '${widget.profile?.remotePort ?? 6466}',
  );
  late final pairingPort = TextEditingController(
    text: '${widget.profile?.pairingPort ?? 6467}',
  );
  late final mac = TextEditingController(text: widget.profile?.mac ?? '');
  final vncPassword = TextEditingController();
  final sonyKey = TextEditingController();
  bool saving = false;
  bool removeVnc = false;
  bool removeSony = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      vncPassword.clear();
      sonyKey.clear();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in [
      name,
      host,
      vncPort,
      remotePort,
      pairingPort,
      mac,
      vncPassword,
      sonyKey,
    ]) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    final previous = widget.profile;
    final random = Random.secure();
    final profile = TvProfile(
      id:
          previous?.id ??
          List.generate(
            16,
            (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join(),
      name: name.text.trim(),
      host: host.text.trim(),
      vncPort: int.parse(vncPort.text),
      remotePort: int.parse(remotePort.text),
      pairingPort: int.parse(pairingPort.text),
      mac: mac.text.trim().isEmpty ? null : mac.text.trim(),
      layout: previous?.layout ?? [],
      favorites: previous?.favorites ?? [],
      recents: previous?.recents ?? [],
      macros: previous?.macros ?? [],
      droidVnc: previous?.droidVnc ?? false,
      pointerVerified: previous?.pointerVerified ?? false,
    );
    try {
      final credentials =
          vncPassword.text.isEmpty &&
              sonyKey.text.isEmpty &&
              !removeVnc &&
              !removeSony
          ? null
          : TvCredentials(
              vncPassword: removeVnc
                  ? ''
                  : vncPassword.text.isEmpty
                  ? null
                  : vncPassword.text,
              sonyKey: removeSony
                  ? ''
                  : sonyKey.text.isEmpty
                  ? null
                  : sonyKey.text,
            );
      final result = await widget.model.api.saveProfile(profile, credentials);
      await widget.model.reload();
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = t(TvModel.errorKey(e));
          saving = false;
        });
      }
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    bool port = false,
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: t(label)),
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: !secret,
      enableIMEPersonalizedLearning: !secret,
      keyboardType: port ? TextInputType.number : TextInputType.text,
      inputFormatters: port
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ]
          : null,
      validator: (value) {
        if (required && (value?.trim().isEmpty ?? true)) return t(label);
        if (port &&
            (int.tryParse(value ?? '') == null ||
                int.parse(value!) < 1 ||
                int.parse(value) > 65535)) {
          return t('invalidPort');
        }
        if (label == 'mac' &&
            value!.isNotEmpty &&
            !RegExp(r'^[0-9a-fA-F]{12}$')
                .hasMatch(value.replaceAll(RegExp('[:-]'), ''))) {
          return t('invalidMac');
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t(widget.profile == null ? 'addTv' : 'edit')),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(name, 'name', required: true),
              field(host, 'address', required: true),
              Text(t('addressHint')),
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(t('settings')),
                tilePadding: EdgeInsets.zero,
                children: [
                  field(vncPort, 'vncPort', port: true),
                  field(vncPassword, 'vncPassword', secret: true),
                  if (widget.profile?.hasVncPassword == true)
                    CheckboxListTile(
                      title: Text(t('removeSavedSecret')),
                      subtitle: Text(t('vncPassword')),
                      value: removeVnc,
                      onChanged: (value) =>
                          setState(() => removeVnc = value ?? false),
                    ),
                  Text(t('classicVnc')),
                  const SizedBox(height: 16),
                  field(sonyKey, 'sonyKey', secret: true),
                  if (widget.profile?.hasSonyKey == true)
                    CheckboxListTile(
                      title: Text(t('removeSavedSecret')),
                      subtitle: Text(t('sonyKey')),
                      value: removeSony,
                      onChanged: (value) =>
                          setState(() => removeSony = value ?? false),
                    ),
                  field(remotePort, 'remotePort', port: true),
                  field(pairingPort, 'pairingPort', port: true),
                  field(mac, 'mac'),
                ],
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: Text(t('cancel')),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              )
            : Text(t('save')),
      ),
    ],
  );
}

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key, required this.model, required this.onSelected});
  final TvModel model;
  final ValueChanged<TvProfile> onSelected;
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<DiscoveredTv> discovered = [];
  bool searching = false;
  bool searched = false;
  Future<void> discover() async {
    var permitted = false;
    setState(() {
      searching = true;
      searched = true;
    });
    final results = await widget.model.guard(() async {
      if (!await widget.model.requestNetworkAccess()) {
        widget.model.report('permissionBody');
        return <DiscoveredTv>[];
      }
      permitted = true;
      return widget.model.api.discover();
    });
    if (mounted) {
      setState(() {
        discovered = {for (final tv in results ?? <DiscoveredTv>[]) tv.host: tv}
            .values
            .toList();
        searching = false;
        searched = permitted && results != null;
      });
    }
  }

  Future<void> add({TvProfile? profile, DiscoveredTv? device}) async {
    final saved = await editDevice(
      context,
      widget.model,
      profile: profile,
      discovered: device,
    );
    if (saved != null && profile == null) widget.onSelected(saved);
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t('devices'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: () => add(),
                tooltip: t('addTv'),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.model.networkPermissionDenied)
            NetworkPermissionPanel(widget.model),
          if (widget.model.profiles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(t('noDevices')),
            ),
          for (final tv in widget.model.profiles)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                leading: const Icon(Icons.tv),
                title: Text(tv.name),
                subtitle: Text(tv.host),
                onTap: () => widget.onSelected(tv),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'edit') await add(profile: tv);
                    if (action == 'forget' &&
                        context.mounted &&
                        await confirm(
                          context,
                          'forgetTitle',
                          'forgetBody',
                          'remove',
                        )) {
                      await widget.model.forget(tv);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(t('edit'))),
                    PopupMenuItem(value: 'forget', child: Text(t('forget'))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: searching ? null : discover,
            icon: const Icon(Icons.radar),
            label: Text(t('discover')),
          ),
          OutlinedButton.icon(
            onPressed: () => add(),
            icon: const Icon(Icons.edit_outlined),
            label: Text(t('manual')),
          ),
          if (searching)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (searched && !searching && discovered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(t('discoveryEmpty')),
            ),
          for (final tv in discovered)
            ListTile(
              leading: const Icon(Icons.connected_tv),
              title: Text(tv.name),
              subtitle: Text(tv.host),
              trailing: const Icon(Icons.add),
              onTap: () => add(device: tv),
            ),
        ],
      ),
    ),
  );
}

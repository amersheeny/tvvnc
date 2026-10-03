import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../model/tv_model.dart';
import 'catalog_pages.dart';
import 'widgets.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage(this.model, {super.key});
  final TvModel model;
  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  String? report;
  bool testing = false;
  Future<String?> test() async {
    final target = widget.model.target;
    if (target == null) return null;
    setState(() => testing = true);
    final result = await widget.model.guard(
      () =>
          widget.model.api.diagnosticReport(target.deviceId, target.sessionId),
    );
    if (mounted) {
      setState(() {
        report = result;
        testing = false;
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.model.state;
    final input = s?.inputs.where((i) => i.uri == s.currentInput).firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          t('diagnostics'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (s?.connectionStage == 'reconnectPaused')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(t('standbyIntent')),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: testing ? null : test,
              icon: const Icon(Icons.network_check),
              label: Text(t('testConnections')),
            ),
            OutlinedButton(
              onPressed: () => refreshTv(widget.model),
              child: Text(t('refreshCapabilities')),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final text = await test();
                if (text != null) {
                  await Clipboard.setData(ClipboardData(text: text));
                  widget.model.report('reportCopied');
                }
              },
              icon: const Icon(Icons.copy),
              label: Text(t('copyReport')),
            ),
          ],
        ),
        if (testing) const LinearProgressIndicator(),
        const SizedBox(height: 20),
        InfoRow(t('tv'), t(s?.power ?? 'unknown')),
        InfoRow(
          t('currentInput'),
          input?.label?.isNotEmpty == true
              ? '${input!.name} — ${input.label}'
              : input?.name ?? s?.currentInput ?? t('unknown'),
        ),
        InfoRow(t('currentApp'), s?.currentApp ?? t('unknown')),
        if (s?.volumeTarget == null)
          InfoRow(t('volume'), s?.volume?.toString() ?? t('unknown'))
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              volumeLabel(
                s?.volume?.toString() ?? t('unknown'),
                s?.volumeTarget,
              ),
            ),
          ),
        InfoRow(
          t('muted'),
          s?.muted == null ? t('unknown') : t(s!.muted! ? 'yes' : 'no'),
        ),
        const Divider(),
        for (final transport in s?.transports ?? <TransportInfo>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              t(switch (transport.id) {
                'remote' => 'androidRemote',
                'sony' => 'sonyApi',
                _ => 'vnc',
              }),
            ),
            subtitle: Text(
              '${availability(transport.state)}${transport.latencyMs == null ? '' : ' · ${transport.latencyMs} ms'}',
            ),
            trailing: IconButton(
              tooltip: t('reconnect'),
              icon: const Icon(Icons.refresh),
              onPressed: () => widget.model.onTarget(
                (target) => widget.model.api.reconnectTransport(
                  target.deviceId,
                  target.sessionId,
                  transport.id,
                ),
              ),
            ),
          ),
        const Divider(),
        InfoRow(t('address'), widget.model.selected?.host ?? t('unknown')),
        InfoRow(t('mac'), s?.mac ?? widget.model.selected?.mac ?? t('unknown')),
        InfoRow(t('model'), s?.model ?? t('unknown')),
        InfoRow(t('firmware'), s?.firmware ?? t('unknown')),
        InfoRow(t('serviceVersion'), s?.remoteVersion ?? t('unknown')),
        const SizedBox(height: 20),
        Text(t('capabilities'), style: Theme.of(context).textTheme.titleLarge),
        for (final cap in s?.capabilities ?? <CapabilityInfo>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              cap.state == Availability.ready
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
            ),
            title: Text(
              t(switch (cap.id) {
                'pointer' => 'screenPointer',
                'sonyIrcc' => 'sonyIrcc',
                'key' => 'remote',
                'text' => 'nativeText',
                'appLink' => 'openLink',
                'wake' => 'wakeOnLan',
                'power' => 'powerState',
                'absoluteVolume' => 'volume',
                _ => cap.id,
              }),
            ),
            subtitle: Text(
              cap.state == Availability.unknown && cap.observedAt == 0
                  ? t('notCheckedYet')
                  : availability(cap.state),
            ),
          ),
        const SizedBox(height: 20),
        Text(t('errors'), style: Theme.of(context).textTheme.titleLarge),
        if (widget.model.iconError != null)
          InfoRow(t('apps'), t(widget.model.iconError!)),
        for (final transport
            in s?.transports.where((p) => p.errorCode != null) ??
                <TransportInfo>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              t(switch (transport.id) {
                'remote' => 'androidRemote',
                'sony' => 'sonyApi',
                _ => 'vnc',
              }),
            ),
            subtitle: Text(t(TvModel.codeKey(transport.errorCode))),
          ),
        if (report != null)
          ExpansionTile(
            key: const ValueKey('diagnostic-report'),
            title: Text(t('testConnections')),
            children: [SelectableText(report!)],
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            final target = widget.model.target;
            if (await confirm(
                  context,
                  'rebootTitle',
                  'rebootBody',
                  'restart',
                ) &&
                target != null) {
              await widget.model.command(
                CommandKind.reboot,
                origin: target,
                confirmed: true,
              );
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: Text(t('reboot')),
        ),
      ],
    );
  }
}

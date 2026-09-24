import 'dart:convert';

import 'package:flutter/material.dart';

import 'widgets.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  AssetBundle? bundle;
  Future<Map<String, dynamic>>? policy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = DefaultAssetBundle.of(context);
    if (bundle == current) return;
    bundle = current;
    policy = current
        .loadString('assets/privacy-policy.json', cache: false)
        .then((value) => jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: policy,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(t('privacyUnavailable')),
        );
      }
      final data = snapshot.data;
      if (data == null) return const Center(child: CircularProgressIndicator());
      final styles = Theme.of(context).textTheme;
      Widget paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SelectableText(text, style: styles.bodyLarge),
      );
      return SingleChildScrollView(
        key: const ValueKey('privacy-document'),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    data['title'] as String,
                    style: styles.headlineSmall,
                  ),
                ),
                const SizedBox(height: 12),
                paragraph((data['metadata'] as List).cast<String>().join('\n')),
                paragraph(data['introduction'] as String),
                for (final section in data['sections'] as List) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      section['heading'] as String,
                      style: styles.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final text in section['paragraphs'] as List)
                    paragraph(text as String),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

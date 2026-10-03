import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';

class EditorSettings {
  const EditorSettings({this.inputType, this.imeOptions, this.actionLabel});
  factory EditorSettings.from(EditorInfo editor) => EditorSettings(
    inputType: editor.inputType,
    imeOptions: editor.imeOptions,
    actionLabel: editor.actionLabel,
  );
  final int? inputType;
  final int? imeOptions;
  final String? actionLabel;
  bool get hasCustomAction => actionLabel != null;
  bool get known => inputType != null;
  int get kind => (inputType ?? 0) & 0xf;
  bool get password =>
      const {0x81, 0x91, 0xe1, 0x12}.contains((inputType ?? 0) & 0xfff);
  bool get multiline => !known || kind == 1 && inputType! & 0x20000 != 0;

  TextInputType keyboardType({required bool hidden, required bool sensitive}) {
    if (kind == 2) {
      return TextInputType.numberWithOptions(
        signed: inputType! & 0x1000 != 0,
        decimal: inputType! & 0x2000 != 0,
      );
    }
    if (kind == 3) return TextInputType.phone;
    if (kind == 4) return TextInputType.datetime;
    if (hidden) return TextInputType.text;
    if (sensitive) return TextInputType.visiblePassword;
    return switch ((inputType ?? 0) & 0xfff) {
      0x11 => TextInputType.url,
      0x21 || 0xd1 => TextInputType.emailAddress,
      _ => multiline ? TextInputType.multiline : TextInputType.text,
    };
  }

  TextInputAction action({required bool hidden}) {
    final newline = !hidden && multiline;
    if (hasCustomAction) {
      return newline ? TextInputAction.newline : TextInputAction.none;
    }
    if (!known) return newline ? TextInputAction.newline : TextInputAction.done;
    final options = imeOptions ?? 0;
    if (options & 0x40000000 != 0 || options & 0xff == 1) {
      return newline ? TextInputAction.newline : TextInputAction.none;
    }
    return switch (options & 0xff) {
      2 => TextInputAction.go,
      3 => TextInputAction.search,
      4 => TextInputAction.send,
      5 => TextInputAction.next,
      6 => TextInputAction.done,
      7 => TextInputAction.previous,
      _ => newline ? TextInputAction.newline : TextInputAction.done,
    };
  }
}

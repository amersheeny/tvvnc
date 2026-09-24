import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/model/tv_model.dart';
import 'package:tv_vnc/ui/copy.dart';

void main() {
  test('pairing failures retain their distinct reviewed messages', () {
    for (final entry in {
      'secure_connection_failed': 'secureConnectionFailed',
      'pairing_unavailable': 'pairingUnavailable',
      'pairing_protocol_error': 'pairingUnavailable',
      'pairing_timeout': 'pairingTimedOut',
      'pairing_rejected': 'pairingFailed',
    }.entries) {
      expect(TvModel.codeKey(entry.key), entry.value);
      expect(Copy.values.containsKey(entry.value), isTrue);
      expect(TvModel.codeKey(entry.key), isNot('connectionFailed'));
    }
  });

  test('English source and compiled UI strings stay identical', () {
    final source = jsonDecode(File('assets/copy/en.json').readAsStringSync());
    expect(source, Copy.values);
  });
}

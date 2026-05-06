import 'package:flutter_test/flutter_test.dart';
import 'package:wireguard_ui_client/api/models/client_models.dart';

void main() {
  group('PeerTrafficRow.mapFromJson', () {
    test('parses pubkey map with rx, tx, connected', () {
      final raw = <dynamic, dynamic>{
        'pkA': {'rx': 100, 'tx': 200, 'connected': true},
        'pkB': {'rx': 0, 'tx': 0},
      };
      final m = PeerTrafficRow.mapFromJson(raw);
      expect(m.length, 2);
      expect(m['pkA']!.rx, 100);
      expect(m['pkA']!.tx, 200);
      expect(m['pkA']!.connected, isTrue);
      expect(m['pkB']!.connected, isFalse);
    });

    test('non-map values are skipped', () {
      final raw = <dynamic, dynamic>{'k': 'not-a-map'};
      final m = PeerTrafficRow.mapFromJson(raw);
      expect(m, isEmpty);
    });

    test('returns empty for non-map input', () {
      expect(PeerTrafficRow.mapFromJson(null), isEmpty);
      expect(PeerTrafficRow.mapFromJson([]), isEmpty);
    });
  });
}

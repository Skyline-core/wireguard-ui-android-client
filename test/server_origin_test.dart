import 'package:flutter_test/flutter_test.dart';
import 'package:wireguard_ui_client/core/config/server_origin.dart';

void main() {
  group('ServerOrigin.splitUrl bare input', () {
    test('IPv4 with port and path prefers http', () {
      final r = ServerOrigin.splitUrl('192.168.0.10:8443/wg');
      expect(r.origin, 'http://192.168.0.10:8443');
      expect(r.basePath, '/wg');
    });

    test('IPv4 without port prefers http', () {
      final r = ServerOrigin.splitUrl('10.0.0.1');
      expect(r.origin, 'http://10.0.0.1');
      expect(r.basePath, '');
    });

    test('localhost prefers http', () {
      final r = ServerOrigin.splitUrl('localhost:3000/peers');
      expect(r.origin, 'http://localhost:3000');
      expect(r.basePath, '/peers');
    });

    test('bare hostname prefers https', () {
      final r = ServerOrigin.splitUrl('vpn.example.net/wg');
      expect(r.origin, 'https://vpn.example.net');
      expect(r.basePath, '/wg');
    });

    test('explicit http is preserved', () {
      final r = ServerOrigin.splitUrl('http://192.168.1.5:5000');
      expect(r.origin, 'http://192.168.1.5:5000');
    });

    test('explicit https is preserved', () {
      final r = ServerOrigin.splitUrl('https://router.lan/admin');
      expect(r.origin, 'https://router.lan');
      expect(r.basePath, '/admin');
    });
  });
}

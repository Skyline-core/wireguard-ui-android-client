/// Mirrors wireguard-ui JSON (`model.Client` inside `ClientData`).
class WgClient {
  const WgClient({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.privateKey,
    required this.presharedKey,
    required this.allocatedIps,
    required this.allowedIps,
    required this.extraAllowedIps,
    required this.endpoint,
    required this.useServerDns,
    required this.enabled,
    required this.email,
    required this.additionalNotes,
  });

  final String id;
  final String name;
  final String publicKey;
  final String privateKey;
  final String presharedKey;
  final List<String> allocatedIps;
  final List<String> allowedIps;
  final List<String> extraAllowedIps;
  final String endpoint;
  final bool useServerDns;
  final bool enabled;
  final String email;
  final String additionalNotes;

  /// Draft for `POST /new-client` — server may generate keys when empty.
  factory WgClient.draftNew({
    required String name,
    required List<String> allocatedIps,
    List<String> allowedIps = const ['0.0.0.0/0', '::/0'],
  }) =>
      WgClient(
        id: '',
        name: name,
        publicKey: '',
        privateKey: '',
        presharedKey: '',
        allocatedIps: allocatedIps,
        allowedIps: allowedIps,
        extraAllowedIps: const [],
        endpoint: '',
        useServerDns: true,
        enabled: true,
        email: '',
        additionalNotes: '',
      );

  factory WgClient.fromJson(Map<String, dynamic> j) => WgClient(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        publicKey: '${j['public_key'] ?? ''}',
        privateKey: '${j['private_key'] ?? ''}',
        presharedKey: '${j['preshared_key'] ?? ''}',
        allocatedIps: _strList(j['allocated_ips']),
        allowedIps: _strList(j['allowed_ips']),
        extraAllowedIps: _strList(j['extra_allowed_ips']),
        endpoint: '${j['endpoint'] ?? ''}',
        useServerDns: j['use_server_dns'] == true,
        enabled: j['enabled'] != false,
        email: '${j['email'] ?? ''}',
        additionalNotes: '${j['additional_notes'] ?? ''}',
      );

  static List<String> _strList(dynamic v) {
    if (v is List) return v.map((e) => '$e').toList();
    return [];
  }
}

/// Envelope `{ Client?: {...}, QRCode?: "..."}` and lowercase field variants.
class WgClientEnvelope {
  const WgClientEnvelope({required this.client, this.qrCode});

  final WgClient client;
  final String? qrCode;

  factory WgClientEnvelope.fromJson(Map<String, dynamic> j) {
    final inner =
        (j['Client'] ?? j['client']) as Map<String, dynamic>? ?? j;
    return WgClientEnvelope(
      client: WgClient.fromJson(inner),
      qrCode: j['QRCode']?.toString() ?? j['qr_code']?.toString(),
    );
  }

  factory WgClientEnvelope.fromFlexible(Map<String, dynamic> j) {
    final nested = j['Client'] ?? j['client'];
    if (nested is Map<String, dynamic>) {
      return WgClientEnvelope(
        client: WgClient.fromJson(nested),
        qrCode: j['QRCode']?.toString() ?? j['qr_code']?.toString(),
      );
    }
    return WgClientEnvelope(client: WgClient.fromJson(j));
  }

  static List<WgClientEnvelope> listFromResponse(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(WgClientEnvelope.fromFlexible)
        .toList();
  }
}

class PeerTrafficRow {
  const PeerTrafficRow({required this.rx, required this.tx});

  /// Bytes received by the WireGuard interface **from** this peer (peer → server).
  final int rx;
  /// Bytes transmitted **to** this peer from the server (server → peer).
  final int tx;

  /// Peer perspective: volume downloaded through the tunnel from the VPN server.
  int get downloadBytes => tx;
  /// Peer perspective: volume uploaded into the tunnel toward the server.
  int get uploadBytes => rx;

  factory PeerTrafficRow.fromJson(Map<String, dynamic> j) => PeerTrafficRow(
        rx: (j['rx'] as num?)?.toInt() ?? 0,
        tx: (j['tx'] as num?)?.toInt() ?? 0,
      );

  /// Map public key → [PeerTrafficRow].
  static Map<String, PeerTrafficRow> mapFromJson(dynamic raw) {
    final out = <String, PeerTrafficRow>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) {
          final m = Map<String, dynamic>.from(v as Map);
          out['$k'] = PeerTrafficRow.fromJson(m);
        }
      });
    }
    return out;
  }
}
